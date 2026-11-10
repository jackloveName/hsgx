import 'dart:convert';

import 'package:encrypt/encrypt.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/services/auth_service.dart';
import 'package:http/http.dart' as http;

class FakeAuthClient extends http.BaseClient {
  http.Request? lastRequest;
  final List<http.Request> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request) {
      lastRequest = request;
      requests.add(request);
    }
    final bytes = utf8.encode(
      jsonEncode({
        'code': '00000',
        'data': {'accessToken': 'access-token'},
      }),
    );
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  test('密码登录发送 AES-ECB 加密后的密码与访问凭证', () async {
    final client = FakeAuthClient();
    final service = AuthService(client: client);

    final session = await service.loginWithPassword(
      phone: '13800138000',
      password: 'secret123',
    );

    expect(session.token, 'access-token');
    final body = jsonDecode(client.lastRequest!.body) as Map;
    expect(body['loginStatus'], 2);
    expect(body['userName'], '13800138000');
    expect(body['appBrand'], '花拾归匣');

    final decrypter = crypto.Encrypter(
      crypto.AES(
        crypto.Key.fromUtf8('-mall--password-'),
        mode: crypto.AESMode.ecb,
      ),
    );
    final plain = decrypter.decrypt64(
      body['passWord'].toString(),
      iv: crypto.IV.fromLength(0),
    );
    expect(plain, endsWith('secret123'));
  });

  test('个人资料、退出和注销使用旧版接口路径与鉴权头', () async {
    final client = FakeAuthClient();
    final service = AuthService(client: client);

    await service.updateUserProfile(
      token: 'token-1',
      name: '新名字',
      avatarPath: 'https://example.com/avatar.png',
      birthday: '1996-08-12',
      gender: '女',
    );
    expect(client.lastRequest?.method, 'PUT');
    expect(client.lastRequest?.url.path, '/mall_user/user/set_user_info');
    expect(client.lastRequest?.headers['Authorization'], 'token-1');
    final body = jsonDecode(client.lastRequest!.body) as Map;
    expect(body['nickName'], '新名字');
    expect(body['birthDate'], '1996-08-12');

    await service.logout('token-2');
    expect(client.lastRequest?.method, 'POST');
    expect(client.lastRequest?.url.path, '/mall_auth/ma/login_out');
    expect(client.lastRequest?.headers['Authorization'], 'token-2');

    await service.destroyAccount('token-3');
    expect(client.lastRequest?.method, 'GET');
    expect(client.lastRequest?.url.path, '/mall_user/user/destroy_user');
    expect(client.lastRequest?.url.queryParameters['forceDestroy'], 'false');
    expect(client.lastRequest?.headers['Authorization'], 'token-3');
  });
}
