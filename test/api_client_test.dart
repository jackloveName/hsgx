import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/services/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('HTTP 错误即使带有 JSON 响应体也不会被当作成功', () async {
    final client = ApiClient(
      baseUrl: 'https://example.com',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': '服务器维护中'}),
          503,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    await expectLater(
      client.get('/status'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.message, 'message', '服务器维护中')
            .having((error) => error.code, 'code', '503'),
      ),
    );
  });
}
