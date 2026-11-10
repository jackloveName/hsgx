import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/screens/storage_screen.dart';
import 'package:hsgx/theme.dart';

void main() {
  testWidgets('取消新增收纳位置时不会使用已释放的输入控制器', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showLocationNameDialog(
                    context,
                    title: '新增收纳位置',
                    hintText: '例如：书房抽屉',
                    confirmLabel: '添加',
                  );
                },
                child: const Text('新增收纳位置'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('新增收纳位置').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '书房抽屉');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('确认新增收纳位置会返回去除首尾空格的名称', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showLocationNameDialog(
                    context,
                    title: '新增收纳位置',
                    hintText: '例如：书房抽屉',
                    confirmLabel: '添加',
                  );
                },
                child: const Text('打开弹窗'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开弹窗'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  阅读角  ');
    await tester.tap(find.text('添加'));
    await tester.pumpAndSettle();

    expect(result, '阅读角');
    expect(tester.takeException(), isNull);
  });
}
