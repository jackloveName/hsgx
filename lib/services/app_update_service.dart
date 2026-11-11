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
        barrierColor: const Color(0x990D1512),
        builder: (dialogContext) => PopScope(
          canPop: canDismiss,
          child: _AppUpdateDialog(
            currentVersion: package.version,
            info: info,
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

class _AppUpdateDialog extends StatelessWidget {
  const _AppUpdateDialog({
    required this.currentVersion,
    required this.info,
    required this.onLater,
    required this.onUpdate,
  });

  final String currentVersion;
  final AppUpdateInfo info;
  final VoidCallback? onLater;
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final downloadConfigured = info.downloadUrl.isNotEmpty;
    final notes = info.notes.isEmpty ? '包含体验优化和问题修复。' : info.notes;
    return Dialog(
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
                      const SizedBox(height: 22),
                      _VersionRoute(
                        currentVersion: currentVersion,
                        latestVersion: info.version,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notes,
                        style: TextStyle(
                          color: context.appTextColor.withValues(alpha: 0.82),
                          fontSize: 12,
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (!downloadConfigured)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: onLater,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text('关闭'),
                          ),
                        )
                      else if (onLater != null)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onLater,
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
                              child: FilledButton(
                                onPressed: onUpdate,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text('立即更新'),
                              ),
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: onUpdate,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text('立即更新'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
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
