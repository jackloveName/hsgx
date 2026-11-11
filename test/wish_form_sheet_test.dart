import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/wishlist_screen.dart';
import 'package:hsgx/theme.dart';

void main() {
  testWidgets('心愿弹窗打开后等待用户点击输入框再聚焦', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showWishEntrySheet(context),
                child: const Text('打开心愿弹窗'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开心愿弹窗'));
    await tester.pumpAndSettle();

    final nameField = find.widgetWithText(TextField, '想要什么');
    expect(find.text('购买动机'), findsNothing);
    expect(find.text('现在需要'), findsNothing);
    final editable = tester.widget<EditableText>(
      find.descendant(of: nameField, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(nameField);
    await tester.pump();

    expect(editable.focusNode.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('键盘出现时心愿弹窗保持在键盘上方且内部可滚动', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              viewInsets: const EdgeInsets.only(bottom: 300),
              padding: const EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showWishEntrySheet(context),
                child: const Text('打开心愿弹窗'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开心愿弹窗'));
    await tester.pumpAndSettle();

    final sheet = tester.getRect(find.byKey(const Key('wish-form-sheet')));
    expect(sheet.top, greaterThan(100));
    expect(sheet.bottom, lessThanOrEqualTo(544));
    expect(find.text('记一愿'), findsOneWidget);
    expect(find.text('先把它留在这里，过几天再决定要不要带回家。'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('编辑已放弃心愿后可以重新放入心愿匣', (tester) async {
    WishEntry? updated;
    final abandoned = WishEntry(
      id: 'abandoned',
      name: '已经放弃的心愿',
      createdAt: '2026-01-01T00:00:00.000',
      status: 'abandoned',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () async {
                  updated = await showWishEntrySheet(
                    context,
                    initial: abandoned,
                  );
                },
                child: const Text('编辑心愿'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('编辑心愿'));
    await tester.pumpAndSettle();

    expect(find.text('保存'), findsOneWidget);

    final reopenButton = find.text('保存');
    await tester.ensureVisible(reopenButton);
    await tester.pumpAndSettle();
    await tester.tap(reopenButton);
    await tester.pumpAndSettle();

    expect(updated?.status, 'cooling');
    expect(updated?.id, abandoned.id);
    expect(updated?.createdAt, isNot(abandoned.createdAt));
  });

  testWidgets('新增心愿时预计价格为必填项', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showWishEntrySheet(context),
                child: const Text('打开心愿弹窗'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开心愿弹窗'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '想要什么'), '新相机');

    final submit = find.text('保存');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('请填写预计价格'), findsOneWidget);
    expect(find.text('记一愿'), findsOneWidget);
  });
}
