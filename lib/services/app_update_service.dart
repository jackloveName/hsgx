import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets.dart';
import 'api/api_client.dart';
import 'api/api_settings.dart';
import 'api/config_api.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.notes,
    required this.force,
  });

  final String version;
  final String downloadUrl;
  final String notes;
  final bool force;
}

class AppUpdateService {
  AppUpdateService({http.Client? client, ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(client: client) {
    _config = ConfigApi(_api);
  }

  static const _skipKey = 'hsgx.appUpdate.skipped';
  final ApiClient _api;
  late final ConfigApi _config;

  Future<void> checkAndShow(BuildContext context) async {
    AppUpdateInfo? update;
    try {
      final raw = await _config.readPublic(ApiSettings.appBrand);
      final config = _configMap(raw);
      final package = await PackageInfo.fromPlatform();
      update = parseUpdateInfo(
        config,
        currentVersion: package.version,
        isIOS: defaultTargetPlatform == TargetPlatform.iOS,
      );
      if (update == null) return;
      final info = update;

      final preferences = await SharedPreferences.getInstance();
      final skipped = preferences.getString(_skipKey) ?? '';
      if (!info.force) {
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
      await showDialog<void>(
        context: context,
        barrierDismissible: canDismiss,
        builder: (dialogContext) => PopScope(
          canPop: canDismiss,
          child: AlertDialog(
            title: const Text('发现新版本'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UpdateBadge(
                    currentVersion: package.version,
                    latestVersion: info.version,
                    force: info.force,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    info.notes.isEmpty ? '包含体验优化和问题修复。' : info.notes,
                    style: const TextStyle(
                      color: Color(0xFF66635D),
                      fontSize: 12,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (canDismiss)
                TextButton(
                  onPressed: () async {
                    if (invalidForceConfig) {
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      return;
                    }
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      _skipKey,
                      '${info.version}|${DateTime.now().toIso8601String()}',
                    );
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: Text(invalidForceConfig ? '关闭' : '稍后'),
                ),
              FilledButton(
                onPressed: info.downloadUrl.isEmpty
                    ? null
                    : () => _openDownload(context, info.downloadUrl),
                child: Text(info.downloadUrl.isEmpty ? '下载地址未配置' : '立即更新'),
              ),
            ],
          ),
        ),
      );
    } on Object catch (error) {
      // Version checks are silent. The next home entry will retry.
      if (kDebugMode && context.mounted) {
        debugPrint('App update check failed: $error');
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
    return AppUpdateInfo(
      version: latest,
      downloadUrl: url,
      notes: notes,
      force: type == 2,
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

class _UpdateBadge extends StatelessWidget {
  const _UpdateBadge({
    required this.currentVersion,
    required this.latestVersion,
    required this.force,
  });

  final String currentVersion;
  final String latestVersion;
  final bool force;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.lerp(primary, Colors.white, 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            force
                ? Icons.system_update_alt_rounded
                : Icons.new_releases_outlined,
            color: primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '当前 $currentVersion  →  最新 $latestVersion',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          if (force)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '强制更新',
                style: TextStyle(
                  color: Color(0xFFC04F68),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
