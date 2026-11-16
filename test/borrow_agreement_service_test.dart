import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/services/borrow_agreement_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('服务配置从嵌套 paramValue 中读取 h5DownloadUrl', () async {
    final service = BorrowAgreementService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': '00000',
            'data': {
              'paramValue': jsonEncode({
                'h5DownloadUrl': 'https://example.com/service?from=app',
              }),
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    addTearDown(service.close);

    expect(
      await service.fetchEntryUrl(),
      'https://example.com/service?from=app',
    );
  });

  test('通讯录使用完整接口路径、Token 和参考项目字段上传', () async {
    http.Request? captured;
    final service = BorrowAgreementService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'code': '00000', 'data': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(service.close);

    await service.uploadContacts(
      token: 'token-1',
      userId: 'user-1',
      otherContact: '[{"name":"张三","phone":"13800138000"}]',
    );

    expect(captured?.method, 'POST');
    expect(captured?.url.path, '/mall-connect/kyc/set_other_contact');
    expect(captured?.headers['Authorization'], 'token-1');
    final body = jsonDecode(captured!.body) as Map;
    expect(body['userId'], 'user-1');
    expect(body['otherContact'], contains('13800138000'));
  });

  test('兼容 UniApp web-view 消息包装并解析权限模式', () {
    final contact = AgreementWebAction.parse(
      jsonEncode({
        '__uniapp_bridge__': true,
        'data': {
          'data': {'action': 'needOtherConstact', 'needOtherConstact': '2'},
        },
      }),
    );
    expect(contact?.action, 'needOtherConstact');
    expect(contact?.permissionMode, 2);

    final three = AgreementWebAction.parse(
      jsonEncode({
        'type': 'WEB_INVOKE_APPSERVICE',
        'data': {
          'options': {'timestamp': 1},
          'name': 'postMessage',
          'arg': {
            'data': {'action': 'three', 'path': 'https://example.com/page'},
          },
        },
        'pageId': '',
      }),
    );
    expect(three?.action, 'three');
    expect(three?.path, 'https://example.com/page');

    final directArg = AgreementWebAction.parse({
      'type': 'WEB_INVOKE_APPSERVICE',
      'data': {
        'name': 'postMessage',
        'arg': {'action': 'logout'},
      },
    });
    expect(directArg?.action, 'logout');
  });

  test('WebView 只接受 HTTP(S)，并识别外部下载地址', () {
    expect(isSafeWebUrl('https://example.com'), isTrue);
    expect(isSafeWebUrl('http://example.com/a'), isTrue);
    expect(isSafeWebUrl('javascript:alert(1)'), isFalse);
    expect(isSafeWebUrl('/relative/path'), isFalse);
    expect(isExternalWebUrl('https://apps.apple.com/app/id1'), isTrue);
    expect(isExternalWebUrl('https://example.com/app.apk'), isTrue);
    expect(isExternalWebUrl('https://example.com/page'), isFalse);
  });
}
