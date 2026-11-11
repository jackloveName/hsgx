import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app.dart';

void main() {
  testWidgets('获取验证码不会提前校验隐私和注册协议', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupGate()));
    await tester.pump();

    await tester.tap(find.text('验证码登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('获取验证码'));
    await tester.pump();

    expect(find.text('请输入正确的手机号'), findsOneWidget);
    expect(find.text('请先阅读并同意隐私政策和平台注册协议'), findsNothing);
  });

  testWidgets('点击登录后才校验隐私和注册协议', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupGate()));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    final loginButton = find.text('登录');
    await tester.ensureVisible(loginButton);
    await tester.pumpAndSettle();
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.text('请先阅读并同意隐私政策和平台注册协议'), findsOneWidget);
  });

  testWidgets('键盘完成操作不会提前触发协议校验', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupGate()));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), '13800138000');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.byType(TextFormField).at(1));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('请先阅读并同意隐私政策和平台注册协议'), findsNothing);
  });
}
