import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/services/agreement_service.dart';
import 'package:hsgx/services/api/api_client.dart';

void main() {
  test('远程协议解析会替换运营者并移除危险标签', () {
    final raw = jsonEncode({
      'code': '00000',
      'data':
          '<h1>隐私政策</h1><script>alert(1)</script>'
          '<p>运营者：\${name}<br>联系邮箱：\${email}</p>',
    });

    final html = AgreementService.parseResponseBody(
      raw,
      platform: TargetPlatform.iOS,
      operatorName: '花拾归匣运营者',
      contactEmail: 'privacy@example.com',
    );

    expect(html, contains('花拾归匣运营者'));
    expect(html, contains('privacy@example.com'));
    expect(html, isNot(contains(r'${name}')));
    expect(html, isNot(contains('<script')));
    expect(html, contains('隐私政策'));
    expect(html, isNot(contains('<h1>')));
  });

  test('协议接口业务错误不会被当作正文展示', () {
    expect(
      () => AgreementService.parseResponseBody(
        jsonEncode({'code': 'A00001', 'msg': '暂无配置'}),
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('远程纯文本协议会转换成可渲染段落', () {
    final html = AgreementService.parseResponseBody(
      jsonEncode({
        'code': '200',
        'data': {'content': '第一段\n第二段'},
      }),
    );

    expect(html, contains('第一段'));
    expect(html, contains('第二段'));
    expect(html, isNot(contains('<p>')));
  });
}
