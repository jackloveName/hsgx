import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/screens/privacy_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('首次启动同意协议后进入主应用', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacyGate(child: Scaffold(body: Text('主应用'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('服务协议和隐私政策'), findsOneWidget);
    expect(find.byKey(const Key('privacy-consent-dialog')), findsOneWidget);
    expect(find.text('暂不同意'), findsOneWidget);
    expect(find.text('同意'), findsOneWidget);
    expect(
      tester.getCenter(find.text('暂不同意')).dy,
      tester.getCenter(find.text('同意')).dy,
    );
    expect(find.byIcon(Icons.check_rounded), findsNothing);

    await tester.tap(find.text('同意'));
    await tester.pumpAndSettle();

    expect(find.text('主应用'), findsOneWidget);
    expect(find.byKey(const Key('privacy-consent-dialog')), findsNothing);
  });
}
