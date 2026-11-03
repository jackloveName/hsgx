import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/services/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('统一解析 00000 响应并携带 JSON Token', () async {
    late http.Request captured;
    final client = ApiClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'code': '00000',
            'data': {'ok': true},
          }),
          200,
        );
      }),
    );

    final result = await client.post(
      '/mall/test',
      token: 'token',
      body: {'name': '测试'},
    );

    expect((result as Map)['ok'], true);
    expect(captured.headers['Authorization'], 'token');
    expect(captured.headers['Content-Type'], contains('application/json'));
  });

  test('401 响应会抛出统一鉴权异常', () async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('', 401)),
    );

    await expectLater(
      client.get('/mall/test'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.unauthorized,
          'unauthorized',
          isTrue,
        ),
      ),
    );
  });

  test('网络异常会标记 reachable=false', () async {
    final client = ApiClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      client.get('/mall/test'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.reachable,
          'reachable',
          isFalse,
        ),
      ),
    );
  });
}
