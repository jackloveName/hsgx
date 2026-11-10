import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app.dart';

void main() {
  testWidgets('未登录启动时先显示登录页', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupGate()));
    await tester.pump();

    expect(find.text('花拾归匣'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
    expect(find.text('暂不登录，继续使用游客模式'), findsOneWidget);
  });
}
