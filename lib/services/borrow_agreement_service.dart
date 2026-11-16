import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api/api_client.dart';
import 'api/api_settings.dart';
import 'api/config_api.dart';

class BorrowAgreementService {
  BorrowAgreementService({http.Client? client, ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(client: client) {
    _config = ConfigApi(_api);
  }

  final ApiClient _api;
  late final ConfigApi _config;

  Future<String> fetchEntryUrl() async {
    final response = await _config.readPublic(AppConfig.appBrand);
    final config = _decodeConfig(response);
    final url = config['h5DownloadUrl']?.toString().trim() ?? '';
    if (!isSafeWebUrl(url)) {
      throw const FormatException('服务入口暂未配置');
    }
    return url;
  }

  Future<void> uploadContacts({
    required String token,
    required String userId,
    required String otherContact,
  }) async {
    await _api.post(
      '/mall-connect/kyc/set_other_contact',
      token: token,
      timeout: ApiSettings.configTimeout,
      silent: true,
      body: {'userId': userId, 'otherContact': otherContact},
    );
  }

  void close() => _api.close();

  static Map<String, Object?> _decodeConfig(Object? value) {
    var current = value;
    for (var depth = 0; depth < 8; depth++) {
      if (current is String) {
        try {
          current = jsonDecode(current);
          continue;
        } on FormatException {
          break;
        }
      }
      if (current is! Map) break;
      final map = current.map((key, value) => MapEntry(key.toString(), value));
      if (map.containsKey('h5DownloadUrl')) return map;
      Object? next;
      for (final key in const [
        'data',
        'config',
        'paramValue',
        'value',
        'content',
      ]) {
        if (map[key] != null) {
          next = map[key];
          break;
        }
      }
      if (next == null || identical(next, current)) break;
      current = next;
    }
    return const {};
  }
}

bool isSafeWebUrl(Object? value) {
  final uri = Uri.tryParse(value?.toString().trim() ?? '');
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

bool isExternalWebUrl(Object? value) {
  final text = value?.toString() ?? '';
  return RegExp(
    r'apps\.apple\.com|open_external=true|\.(?:apk|plist)(?:$|[?#])',
    caseSensitive: false,
  ).hasMatch(text);
}

class AgreementWebAction {
  const AgreementWebAction({
    required this.action,
    this.path = '',
    this.permissionMode,
  });

  final String action;
  final String path;
  final int? permissionMode;

  static AgreementWebAction? parse(Object? message) {
    final payload = _unwrap(message);
    if (payload is! Map) return null;
    final map = payload.map((key, value) => MapEntry(key.toString(), value));
    final action = map['action']?.toString().trim() ?? '';
    if (action.isEmpty) return null;
    final rawMode = action == 'needOtherConstact'
        ? map['needOtherConstact'] ?? map['value']
        : null;
    return AgreementWebAction(
      action: action,
      path: map['path']?.toString().trim() ?? '',
      permissionMode: _permissionMode(rawMode),
    );
  }

  static Object? _unwrap(Object? value) {
    var current = value;
    for (var depth = 0; depth < 8; depth++) {
      if (current is String) {
        try {
          current = jsonDecode(current);
          continue;
        } on FormatException {
          return null;
        }
      }
      if (current is List) {
        if (current.isEmpty) return null;
        current = current.first;
        continue;
      }
      if (current is! Map) return current;
      final map = current.map((key, value) => MapEntry(key.toString(), value));
      if (map['detail'] is Map && map['detail']['data'] != null) {
        current = map['detail']['data'];
        continue;
      }
      final arg = map['arg'];
      if (arg is Map) {
        current = arg['data'] ?? arg;
        continue;
      }
      if (map['__uniapp_bridge__'] == true && map['data'] != null) {
        current = map['data'];
        continue;
      }
      if (map['data'] is Map || map['data'] is String) {
        current = map['data'];
        continue;
      }
      return map;
    }
    return null;
  }

  static int? _permissionMode(Object? value) {
    if (value == null || value == '') return null;
    if (value is bool) return value ? 1 : 0;
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null || !number.isFinite) return null;
    return number.toInt();
  }
}
