import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../components/app_brand_icon.dart';
import '../widgets.dart';
import 'api/api_client.dart';
import 'api/api_settings.dart';
import 'api/config_api.dart';
import 'app_update_installer_stub.dart'
    if (dart.library.io) 'app_update_installer_io.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.notes,
    required this.force,
    required this.updateWay,
  });

  final String version;
  final String downloadUrl;
  final String notes;
  final bool force;
  final int updateWay;
}

class AppUpdateService {
  AppUpdateService({http.Client? client, ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(client: client) {
    _config = ConfigApi(_api);
  }

  static const _skipKey = 'hsgx.appUpdate.skipped';
  final ApiClient _api;
  late final ConfigApi _config;

  Future<void> checkAndShow(
    BuildContext context, {
    required bool borrowFlagEnabled,
    bool manual = false,
  }) async {
    if (!borrowFlagEnabled) {
      _api.close();
      if (manual && context.mounted) {
        showAppSnack(context, '当前账号未开启版本更新检查');
      }
      return;
    }
    AppUpdateInfo? update;
    try {
      final raw = await _config.readPublic(ApiSettings.appBrand);
      final config = _configMap(raw);
      final package = await PackageInfo.fromPlatform();
      final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      update = parseUpdateInfo(
        config,
        currentVersion: package.version,
        isIOS: isIOS,
      );
      if (update == null) {
        if (manual && context.mounted) {
          showAppSnack(context, '当前已是最新版本');
        }
        return;
      }
      final info = update;

      final preferences = await SharedPreferences.getInstance();
      final skipped = preferences.getString(_skipKey) ?? '';
      if (!manual && !info.force) {
        final parts = skipped.split('|');
        if (parts.length == 2 && parts[0] == info.version) {
          final skippedAt = DateTime.tryParse(parts[1]);
          if (skippedAt != null &&
              DateTime.now().difference(skippedAt) <
                  const Duration(hours: 24)) {
            return;
          }
        }
      }
      if (!context.mounted) return;
      final invalidForceConfig = update.force && update.downloadUrl.isEmpty;
      final canDismiss = !update.force || invalidForceConfig;
      final supportsInAppInstall =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      final inAppInstall = supportsInAppInstall && info.updateWay != 1;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0x990D1512),
        builder: (dialogContext) => _AppUpdateDialog(
          currentVersion: package.version,
          info: info,
          isIOS: isIOS,
          inAppInstall: inAppInstall,
          canDismiss: canDismiss,
          onLater: canDismiss
              ? () async {
                  if (!invalidForceConfig) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      _skipKey,
                      '${info.version}|${DateTime.now().toIso8601String()}',
                    );
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                }
              : null,
          onUpdate: info.downloadUrl.isEmpty
              ? null
              : () => _openDownload(context, info.downloadUrl),
          onInstall: info.downloadUrl.isEmpty
              ? null
              : (onProgress) async {
                  await downloadAndInstallApk(
                    url: info.downloadUrl,
                    onProgress: onProgress,
                  );
                  if (context.mounted) {
                    showAppSnack(context, '安装程序已打开，请按系统提示完成安装');
                  }
                },
        ),
      );
    } on Object catch (error) {
      if (kDebugMode && context.mounted) {
        debugPrint('App update check failed: $error');
      }
      if (manual && context.mounted) {
        showAppSnack(
          context,
          error is AppUpdateInstallException ? error.message : '暂时无法检查更新，请稍后重试',
        );
      }
    } finally {
      _api.close();
    }
  }

  Future<void> _openDownload(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        showAppSnack(context, '无法打开下载地址，已复制到剪贴板');
      }
    }
  }

  @visibleForTesting
  static AppUpdateInfo? parseUpdateInfo(
    Map<String, Object?> config, {
    required String currentVersion,
    required bool isIOS,
  }) {
    final latest =
        _text(
          isIOS
              ? config['iosAppVersion']
              : config['androidVersion'] ?? config['androidAppVersion'],
        ) ??
        _text(config['version']) ??
        _text(config['versionName']) ??
        _text(config['latestVersion']) ??
        _text(config['newVersion']) ??
        _text(config['appVersion']) ??
        '';
    if (latest.isEmpty) return null;
    final type = int.tryParse(
      _text(isIOS ? config['iosUpdateType'] : config['androidUpdateType']) ??
          '1',
    );
    if (type == 0) return null;
    if (compareVersions(latest, currentVersion) <= 0) return null;
    final url =
        _text(
          isIOS
              ? config['iosAppDownloadUrl']
              : config['androidAppDownloadUrl'] ?? config['androidUrl'],
        ) ??
        _text(config['h5DownloadUrl']) ??
        _text(config['url']) ??
        _text(config['downloadUrl']) ??
        _text(config['storeUrl']) ??
        _text(config['apkUrl']) ??
        '';
    final notes =
        _text(
          isIOS
              ? config['iosVersionDesc'] ?? config['iosUpdateContent']
              : config['androidVersionDesc'] ?? config['androidUpdateContent'],
        ) ??
        _text(config['notes']) ??
        _text(config['note']) ??
        _text(config['content']) ??
        _text(config['desc']) ??
        _text(config['description']) ??
        _text(config['updateLog']) ??
        _text(config['versionDesc']) ??
        '';
    final updateWay = int.tryParse(
      _text(isIOS ? config['iosUpdateWay'] : config['androidUpdateWay']) ??
          (isIOS ? '1' : '0'),
    );
    return AppUpdateInfo(
      version: latest,
      downloadUrl: url,
      notes: notes,
      force: type == 2,
      updateWay: updateWay ?? (isIOS ? 1 : 0),
    );
  }

  @visibleForTesting
  static int compareVersions(String first, String second) {
    List<int> parts(String value) {
      final clean = value.trim().replaceFirst(RegExp(r'^[vV]'), '');
      return clean
          .split(RegExp(r'[.+-]'))
          .map((part) => int.tryParse(part) ?? 0)
          .toList();
    }

    final a = parts(first);
    final b = parts(second);
    final length = a.length > b.length ? a.length : b.length;
    for (var index = 0; index < length; index++) {
      final av = index < a.length ? a[index] : 0;
      final bv = index < b.length ? b[index] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  static Map<String, Object?> _configMap(Object? value) {
    var current = value;
    for (var depth = 0; depth < 6; depth++) {
      if (current is String) {
        try {
          current = jsonDecode(current);
          continue;
        } on FormatException {
          break;
        }
      }
      if (current is Map) {
        final map = current.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        if (map.keys.any(
          (key) => const {
            'iosAppVersion',
            'androidVersion',
            'androidAppVersion',
            'version',
            'versionName',
            'latestVersion',
          }.contains(key),
        )) {
          return map;
        }
        for (final key in const [
          'data',
          'config',
          'paramValue',
          'value',
          'content',
        ]) {
          if (map[key] != null) {
            current = map[key];
            break;
          }
        }
        if (current == map) break;
        continue;
      }
      break;
    }
    return const {};
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

typedef _InstallUpdate = Future<void> Function(ValueChanged<double> onProgress);
typedef _UpdateAction = Future<void> Function();

class _AppUpdateDialog extends StatefulWidget {
  const _AppUpdateDialog({
    required this.currentVersion,
    required this.info,
    required this.isIOS,
    required this.inAppInstall,
    required this.canDismiss,
    required this.onLater,
    required this.onUpdate,
    required this.onInstall,
  });

  final String currentVersion;
  final AppUpdateInfo info;
  final bool isIOS;
  final bool inAppInstall;
  final bool canDismiss;
  final _UpdateAction? onLater;
  final _UpdateAction? onUpdate;
  final _InstallUpdate? onInstall;

  @override
  State<_AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<_AppUpdateDialog> {
  bool _downloading = false;
  double _progress = 0;

  Future<void> _handleLater() async {
    final later = widget.onLater;
    if (later != null) await later();
  }

  Future<void> _handleUpdate() async {
    final install = widget.onInstall;
    if (!widget.inAppInstall || install == null) {
      final update = widget.onUpdate;
      if (update != null) await update();
      return;
    }

    setState(() {
      _downloading = true;
      _progress = 0;
    });
    try {
      await install((value) {
        if (!mounted) return;
        setState(() {
          _progress = value.clamp(0, 1).toDouble();
        });
      });
      if (mounted) {
        setState(() {
          _downloading = false;
          _progress = 0;
        });
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _progress = 0;
      });
      showAppSnack(
        context,
        error is AppUpdateInstallException ? error.message : '更新包下载或安装失败，请稍后重试',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final downloadConfigured = widget.info.downloadUrl.isNotEmpty;
    final notes = widget.info.notes.isEmpty
        ? '包含体验优化和问题修复。'
        : widget.info.notes;
    final updateLabel = widget.isIOS ? '前往 App Store' : '立即更新';
    return PopScope(
      canPop: widget.canDismiss && !_downloading,
      child: Dialog(
        key: const Key('app-update-dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 390,
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                    child: Column(
                      children: [
                        AppBrandIcon(
                          size: 68,
                          radius: 20,
                          imageKey: const Key('app-update-icon'),
                          backgroundColor: scheme.surfaceContainerLowest,
                          shadowColor: primary.withValues(alpha: 0.14),
                          shadowBlur: 22,
                          shadowOffset: const Offset(0, 8),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '版本更新',
                              style: TextStyle(
                                color: primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '应用有新版本了',
                          style: TextStyle(
                            color: context.appTextColor,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _VersionRoute(
                          currentVersion: widget.currentVersion,
                          latestVersion: widget.info.version,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: context.appSurfaceMutedColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.appBorderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '版本 ${widget.info.version}',
                                      style: TextStyle(
                                        color: context.appTextColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.info.force
                                          ? '需要更新后继续使用'
                                          : '更新后体验更稳定',
                                      style: TextStyle(
                                        color: context.appMutedColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.info.force
                                      ? const Color(0xFFFFE8E2)
                                      : primary.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  widget.info.force ? '必须更新' : '新版本',
                                  style: TextStyle(
                                    color: widget.info.force
                                        ? const Color(0xFFA34D3F)
                                        : primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.notes_rounded, size: 16, color: primary),
                            const SizedBox(width: 6),
                            Text(
                              '本次更新',
                              style: TextStyle(
                                color: context.appTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 126),
                          child: SingleChildScrollView(
                            child: Text(
                              notes,
                              style: TextStyle(
                                color: context.appTextColor.withValues(
                                  alpha: 0.82,
                                ),
                                fontSize: 12,
                                height: 1.65,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_downloading) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              key: const Key('app-update-progress'),
                              value: _progress,
                              minHeight: 7,
                              backgroundColor: context.appSurfaceMutedColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _progress >= 1 ? '下载完成，正在打开安装程序' : '正在下载更新包',
                                  style: TextStyle(
                                    color: context.appMutedColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Text(
                                '${(_progress * 100).round()}%',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ] else if (!downloadConfigured)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _handleLater,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text('关闭'),
                            ),
                          )
                        else if (widget.onLater != null)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _handleLater,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.appMutedColor,
                                    minimumSize: const Size(0, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text('稍后'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _handleUpdate,
                                  icon: Icon(
                                    widget.isIOS
                                        ? Icons.open_in_new_rounded
                                        : Icons.download_rounded,
                                    size: 18,
                                  ),
                                  label: Text(updateLabel),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _handleUpdate,
                              icon: Icon(
                                widget.isIOS
                                    ? Icons.open_in_new_rounded
                                    : Icons.download_rounded,
                                size: 18,
                              ),
                              label: Text(updateLabel),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 14,
                              color: context.appMutedColor,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '更新由官方版本配置提供，数据仍保存在你的账号下',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.appMutedColor,
                                  fontSize: 9,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionRoute extends StatelessWidget {
  const _VersionRoute({
    required this.currentVersion,
    required this.latestVersion,
  });

  final String currentVersion;
  final String latestVersion;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        _VersionChip(label: '当前版本', value: currentVersion, muted: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: context.appMutedColor.withValues(alpha: 0.65),
            size: 17,
          ),
        ),
        _VersionChip(label: '最新版本', value: latestVersion, color: primary),
      ],
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.label,
    required this.value,
    this.color,
    this.muted = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = color ?? context.appMutedColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: muted
              ? context.appSurfaceMutedColor
              : Color.lerp(color, scheme.surfaceContainerLowest, 0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: muted
                ? context.appBorderColor
                : color!.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.appMutedColor,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
