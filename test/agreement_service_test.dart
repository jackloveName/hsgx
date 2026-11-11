import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/config/app_config.dart';
import 'package:hsgx/services/agreement_service.dart';
import 'package:hsgx/services/api/api_client.dart';
import 'package:hsgx/services/api/api_settings.dart';

void main() {
  test('协议配置 Key 保持固定并按平台切换运营者信息', () {
    expect(ApiSettings.privacyProtocolKey, 'HSGX_PRIVACY_PROTOC');
    expect(ApiSettings.registerProtocolKey, 'HSGX_REGISTER_PROTOC');

    final android = AppConfig.agreementIdentityFor(TargetPlatform.android);
    expect(android.operatorName, '深圳市亮任网络科技有限公司');
    expect(android.contactEmail, 'williamchavez6095@outlook.com');

    final ios = AppConfig.agreementIdentityFor(TargetPlatform.iOS);
    expect(ios.operatorName, 'Grant Alston Remington');
    expect(ios.contactEmail, 'BarncastleFarquer34@outlook.com');
  });

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

  test('没有占位符时也会按平台补齐运营者和联系邮箱', () {
    final raw = jsonEncode({
      'code': '00000',
      'data': {'content': '这里是协议正文。'},
    });

    final android = AgreementService.parseResponseBody(
      raw,
      platform: TargetPlatform.android,
    );
    expect(android, contains('深圳市亮任网络科技有限公司'));
    expect(android, contains('williamchavez6095@outlook.com'));

    final ios = AgreementService.parseResponseBody(
      raw,
      platform: TargetPlatform.iOS,
    );
    expect(ios, contains('Grant Alston Remington'));
    expect(ios, contains('BarncastleFarquer34@outlook.com'));
  });

  test('安卓运营者和联系邮箱不保留中文方括号', () {
    final raw = jsonEncode({
      'code': '00000',
      'data': '<p>运营者：【\${name}】<br>联系邮箱：【\${email}】</p>',
    });

    final content = AgreementService.parseResponseBody(
      raw,
      platform: TargetPlatform.android,
      operatorName: '深圳市亮任网络科技有限公司',
      contactEmail: 'williamchavez6095@outlook.com',
    );

    expect(content, contains('运营者：深圳市亮任网络科技有限公司'));
    expect(content, contains('联系邮箱：williamchavez6095@outlook.com'));
    expect(content, isNot(contains('【')));
    expect(content, isNot(contains('】')));
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
