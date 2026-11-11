import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/screens/storage_screen.dart';
import 'package:hsgx/theme.dart';

void main() {
  testWidgets('取消归处底部弹窗时不会使用已释放的输入控制器', (tester) async {
    StorageLocationDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showStorageLocationSheet(
                    context,
                    title: '添一处归处',
                    confirmLabel: '添归处',
                  );
                },
                child: const Text('添加归处'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('添加归处'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('storage-location-name-field')),
      '书房抽屉',
    );
    final cancel = find.text('取消');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('归处底部弹窗返回去除空格的名称和所选图标', (tester) async {
    StorageLocationDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  result = await showStorageLocationSheet(
                    context,
                    title: '添一处归处',
                    confirmLabel: '添归处',
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
    await tester.enterText(
      find.byKey(const Key('storage-location-name-field')),
      '  阅读角  ',
    );
    await tester.tap(find.byKey(const Key('storage-location-icon-book')));
    final submit = find.byKey(const Key('storage-location-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(result?.name, '阅读角');
    expect(result?.iconKey, 'book');
    expect(tester.takeException(), isNull);
  });
}
