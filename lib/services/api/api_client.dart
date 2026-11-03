import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_settings.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.code = '',
    this.reachable = true,
    this.unauthorized = false,
  });

  final String message;
  final String code;
  final bool reachable;
  final bool unauthorized;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    this.onUnauthorized,
    this.baseUrl = ApiSettings.baseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final void Function()? onUnauthorized;

  Future<Object?> get(
    String path, {
    Map<String, Object?>? query,
    String? token,
    Duration timeout = ApiSettings.defaultTimeout,
    bool silent = false,
  }) {
    return _request(
      'GET',
      path,
      query: query,
      token: token,
      timeout: timeout,
      silent: silent,
    );
  }

  Future<Object?> post(
    String path, {
    Object? body,
    String? token,
    Duration timeout = ApiSettings.defaultTimeout,
    bool silent = false,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      token: token,
      timeout: timeout,
      silent: silent,
    );
  }

  Future<Object?> put(
    String path, {
    Object? body,
    String? token,
    Duration timeout = ApiSettings.defaultTimeout,
    bool silent = false,
  }) {
    return _request(
      'PUT',
      path,
      body: body,
      token: token,
      timeout: timeout,
      silent: silent,
    );
  }

  Future<void> putExternal(
    String url, {
    required List<int> bytes,
    required String contentType,
    Duration timeout = ApiSettings.configTimeout,
  }) async {
    final response = await _send(
      () => _client.put(
        Uri.parse(url),
        headers: {'Content-Type': contentType},
        body: bytes,
      ),
      timeout,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('文件上传失败（${response.statusCode}）');
    }
  }

  void close() => _client.close();

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
    String? token,
    required Duration timeout,
    required bool silent,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          for (final entry in query.entries)
            if (entry.value != null) entry.key: entry.value.toString(),
        },
      );
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
      if (token != null && token.isNotEmpty) 'Authorization': token,
    };
    final encodedBody = body == null ? null : jsonEncode(body);
    final response = await _send(
      () => switch (method) {
        'POST' => _client.post(uri, headers: headers, body: encodedBody),
        'PUT' => _client.put(uri, headers: headers, body: encodedBody),
        _ => _client.get(uri, headers: headers),
      },
      timeout,
    );

    Object? decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = response.body;
      }
    }
    final map = decoded is Map
        ? decoded.map((key, value) => MapEntry(key.toString(), value))
        : null;
    final code = map?['code']?.toString() ?? '';
    final message =
        map?['msg']?.toString() ?? map?['message']?.toString() ?? '';
    final unauthorized =
        response.statusCode == 401 ||
        const {'401', '000401', 'A000401'}.contains(code) ||
        message.toLowerCase() == 'unauthorized';
    if (unauthorized) {
      onUnauthorized?.call();
      throw ApiException('登录状态已失效，请重新登录', code: code, unauthorized: true);
    }
    if (response.statusCode >= 400 && map == null) {
      throw ApiException(
        silent ? 'HTTP ${response.statusCode}' : '请求失败（${response.statusCode}）',
        code: '${response.statusCode}',
      );
    }
    if (map == null) return decoded;
    if (code == '00000') return map['data'];
    if (code == '200' || code.isEmpty) return map;
    throw ApiException(message.isEmpty ? code : message, code: code);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
    Duration timeout,
  ) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('请求超时，请稍后重试', reachable: false);
    } on http.ClientException {
      throw const ApiException('网络连接失败，请检查网络', reachable: false);
    } on Object catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('网络连接失败，请检查网络：$error', reachable: false);
    }
  }
}
