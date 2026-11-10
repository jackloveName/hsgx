import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api/api_client.dart';
import 'api/api_settings.dart';
import 'api/config_api.dart';

class AgreementService {
  AgreementService({http.Client? client, ApiClient? apiClient})
    : _api = apiClient ?? ApiClient(client: client) {
    _config = ConfigApi(_api);
  }

  static const privacyKey = ApiSettings.privacyProtocolKey;
  static const registerKey = ApiSettings.registerProtocolKey;
  static const _cacheDuration = Duration(minutes: 5);
  static final Map<String, ({String content, DateTime cachedAt})> _cache = {};

  final ApiClient _api;
  late final ConfigApi _config;

  Future<String> fetch(String key, {bool forceRefresh = false}) async {
    final cached = _cache[key];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheDuration) {
      return cached.content;
    }
    final response = await _config.readPublic(key);
    final text = _extractText(response).trim();
    if (text.isEmpty) throw const FormatException('协议内容为空');
    final content = _htmlToPlainText(
      _applyOperator(
        text,
        operatorName: AppConfig.agreementOperatorName,
        contactEmail: AppConfig.agreementContactEmail,
      ),
    );
    if (content.isEmpty) throw const FormatException('协议内容为空');
    _cache[key] = (content: content, cachedAt: DateTime.now());
    return content;
  }

  void close() => _api.close();

  @visibleForTesting
  static String parseResponseBody(
    String raw, {
    TargetPlatform? platform,
    String operatorName = AppConfig.agreementOperatorName,
    String contactEmail = AppConfig.agreementContactEmail,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('协议响应格式错误');
    final body = decoded.map((key, value) => MapEntry(key.toString(), value));
    final code = body['code']?.toString();
    if (code != null && code != '00000' && code != '200') {
      throw ApiException(body['msg']?.toString() ?? '协议内容读取失败');
    }
    final text = _extractText(body['data'] ?? body).trim();
    if (text.isEmpty) throw const FormatException('协议内容为空');
    return _htmlToPlainText(
      _applyOperator(
        text,
        operatorName: operatorName,
        contactEmail: contactEmail,
      ),
    );
  }

  static String _extractText(Object? value, [int depth = 0]) {
    if (depth > 8 || value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return value
          .map((entry) => _extractText(entry, depth + 1).trim())
          .where((entry) => entry.isNotEmpty)
          .join('\n');
    }
    if (value is Map) {
      for (final key in const [
        'paramValue',
        'value',
        'content',
        'text',
        'data',
        'config',
      ]) {
        if (value.containsKey(key)) {
          final result = _extractText(value[key], depth + 1);
          if (result.trim().isNotEmpty) return result;
        }
      }
    }
    return '';
  }

  static String _applyOperator(
    String value, {
    required String operatorName,
    required String contactEmail,
  }) {
    var result = value;
    if (operatorName.trim().isNotEmpty) {
      result = result
          .replaceAll(r'${name}', operatorName.trim())
          .replaceAll('【运营者名称】', operatorName.trim());
    }
    if (contactEmail.trim().isNotEmpty) {
      result = result
          .replaceAll(r'${email}', contactEmail.trim())
          .replaceAll('【联系邮箱】', contactEmail.trim());
    }
    return result;
  }

  static String _htmlToPlainText(String raw) {
    var value = _decodeEntities(raw)
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
        .replaceAll(
          RegExp(
            r'<\s*(script|style|iframe|object|embed)\b[\s\S]*?<\s*/\s*\1\s*>',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(
            r'</(?:p|div|h[1-6]|blockquote|section)>',
            caseSensitive: false,
          ),
          '\n',
        )
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ')
        .replaceAll(RegExp(r'</(?:ul|ol)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '');
    value = value
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n\n');
    return value.trim();
  }

  static String _decodeEntities(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (match) => String.fromCharCode(int.parse(match.group(1)!)),
        )
        .replaceAllMapped(
          RegExp(r'&#x([0-9a-f]+);', caseSensitive: false),
          (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
        )
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&ldquo;', '“')
        .replaceAll('&rdquo;', '”')
        .replaceAll('&mdash;', '—')
        .replaceAll('&middot;', '·');
  }
}
