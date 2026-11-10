import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('记录一个心愿'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
