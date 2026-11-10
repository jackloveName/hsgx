import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/theme.dart';
import 'package:hsgx/widgets.dart';

void main() {
  testWidgets('应用轻提示显示在页面顶部并自动消失', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(3),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAppSnack(context, '已保存'),
                child: const Text('显示提示'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示提示'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final notice = find.byKey(const Key('top-app-notice'));
    expect(find.text('已保存'), findsOneWidget);
    expect(notice, findsOneWidget);
    expect(
      tester.getTopLeft(notice).dy,
      lessThan(tester.getSize(find.byType(Scaffold)).height / 3),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('已保存'), findsNothing);
  });
}
