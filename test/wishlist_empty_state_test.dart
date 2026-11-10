import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/screens/wishlist_screen.dart';
import 'package:hsgx/theme.dart';

void main() {
  testWidgets('心愿匣添加按钮使用页面主题色胶囊样式', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const WishlistScreen()),
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('wishlist-add-button')),
    );
    expect(
      button.style?.backgroundColor?.resolve({}),
      buildAppTheme().colorScheme.primary,
    );
    expect(find.text('记一愿'), findsOneWidget);
  });

  testWidgets('有心愿但当前筛选为空时不再显示心愿匣为空', (tester) async {
    var showedAll = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: WishlistEmptyState(
            hasAnyWishes: true,
            onAdd: () {},
            onShowAll: () => showedAll = true,
          ),
        ),
      ),
    );

    expect(find.text('心愿匣还是空的'), findsNothing);
    expect(find.text('这个状态下还没有心愿'), findsOneWidget);
    expect(find.text('当前筛选状态没有记录，可以查看全部心愿。'), findsOneWidget);
    expect(find.text('查看全部心愿'), findsOneWidget);

    await tester.tap(find.text('查看全部心愿'));
    expect(showedAll, isTrue);
  });

  testWidgets('真正没有心愿时仍显示新建入口', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: WishlistEmptyState(
            hasAnyWishes: false,
            onAdd: () {},
            onShowAll: () {},
          ),
        ),
      ),
    );

    expect(find.text('心愿匣还是空的'), findsOneWidget);
    expect(find.text('记录一个心愿'), findsOneWidget);
  });
}
