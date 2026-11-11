import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/components/filter_pill_bar.dart';
import 'package:hsgx/components/wishlist/wishlist_empty_state.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/wishlist_screen.dart';
import 'package:hsgx/storage/app_state_storage.dart';
import 'package:hsgx/theme.dart';

class _MemoryStorage implements AppStateStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<bool> write(String key, String value) async {
    values[key] = value;
    return true;
  }
}

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

  testWidgets('心愿匣的全部筛选按钮位于第一位', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const WishlistScreen()),
    );
    await tester.pump();

    final filterBar = find.byType(FilterPillBar<String>);
    final all = find.descendant(of: filterBar, matching: find.text('全部'));
    final pending = find.descendant(of: filterBar, matching: find.text('待决定'));

    expect(tester.getTopLeft(all).dx, lessThan(tester.getTopLeft(pending).dx));
    expect(find.widgetWithText(ChoiceChip, '全部'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '全部')).selected,
      isTrue,
    );
  });

  testWidgets('心愿匣顶部显示本月心愿花费和实现数量', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 10, 13);
    final previousMonth = DateTime(now.year, now.month - 1, 20, 13);
    for (final entry in [
      WishEntry(
        id: 'achieved-1',
        name: '已达成一',
        expectedPrice: 3200,
        createdAt: thisMonth.toIso8601String(),
        status: 'achieved',
        achievedAt: thisMonth.toIso8601String(),
      ),
      WishEntry(
        id: 'achieved-2',
        name: '已达成二',
        expectedPrice: 100,
        createdAt: thisMonth.toIso8601String(),
        status: 'achieved',
        achievedAt: thisMonth.toIso8601String(),
      ),
      WishEntry(
        id: 'achieved-last-month',
        name: '上个月达成',
        expectedPrice: 8000,
        createdAt: previousMonth.toIso8601String(),
        status: 'achieved',
        achievedAt: previousMonth.toIso8601String(),
      ),
      WishEntry(
        id: 'abandoned',
        name: '已放弃',
        expectedPrice: 5000,
        createdAt: thisMonth.toIso8601String(),
        status: 'abandoned',
      ),
      WishEntry(
        id: 'cooling',
        name: '冷静中',
        expectedPrice: 999,
        createdAt: thisMonth.toIso8601String(),
      ),
    ]) {
      await store.addWish(entry);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WishlistScreen(store: store),
      ),
    );
    await tester.pump();

    final overview = find.byKey(const Key('wish-spend-overview'));
    expect(
      find.descendant(of: overview, matching: find.text('本月心愿花费')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: overview, matching: find.text('¥3,300')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: overview, matching: find.text('共实现 2 个心愿')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: overview, matching: find.text('待决定')),
      findsNothing,
    );
    expect(
      find.descendant(of: overview, matching: find.text('已决定')),
      findsNothing,
    );
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
    expect(find.text('已达成一'), findsOneWidget);
    expect(find.text('上个月达成'), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('wish-summary-next-month')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('wish-summary-previous-month')));
    await tester.pump();

    final previous = DateTime(now.year, now.month - 1);
    expect(find.text('${previous.year}年${previous.month}月'), findsOneWidget);
    expect(
      find.descendant(of: overview, matching: find.text('¥8,000')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: overview, matching: find.text('共实现 1 个心愿')),
      findsOneWidget,
    );
    expect(find.text('已达成一'), findsNothing);
    expect(find.text('上个月达成'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('wish-summary-next-month')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('wish-summary-next-month')));
    await tester.pump();
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
    expect(
      find.descendant(of: overview, matching: find.text('¥3,300')),
      findsOneWidget,
    );
  });

  testWidgets('心愿列表和详情都不显示旧版购买动机', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addWish(
      WishEntry(
        id: 'legacy-motivation',
        name: '游戏机',
        createdAt: DateTime.now().toIso8601String(),
        desireType: 'need',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WishlistScreen(store: store),
      ),
    );
    await tester.pump();

    expect(find.text('游戏机'), findsOneWidget);
    expect(find.text('购买动机 · 现在需要'), findsNothing);

    await tester.tap(find.text('游戏机'));
    await tester.pumpAndSettle();

    final detailSheet = find.byType(BottomSheet);
    expect(find.text('心愿详情'), findsNothing);
    expect(find.text('预计价格'), findsOneWidget);
    expect(find.text('购买动机 · 现在需要'), findsNothing);
    expect(
      find.descendant(of: detailSheet, matching: find.text('编辑心愿')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: detailSheet, matching: find.text('删除')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('wish-detail-edit'))).width,
      closeTo(
        tester.getSize(find.byKey(const Key('wish-detail-delete'))).width,
        0.1,
      ),
    );
    final deleteButton = tester.widget<TextButton>(
      find.byKey(const Key('wish-detail-delete')),
    );
    expect(
      deleteButton.style?.side?.resolve({}),
      isA<BorderSide>().having((side) => side.width, 'width', greaterThan(0)),
    );
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(
      find.descendant(of: detailSheet, matching: find.text('拾入心愿匣')),
      findsNothing,
    );
    expect(
      find.descendant(of: detailSheet, matching: find.text('放弃')),
      findsNothing,
    );
  });

  testWidgets('心愿详情关闭按钮显示图标', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addWish(
      WishEntry(
        id: 'text-close-button',
        name: '图标关闭按钮',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WishlistScreen(store: store),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('图标关闭按钮'));
    await tester.pumpAndSettle();

    final detailSheet = find.byType(BottomSheet);
    final closeButton = find.byKey(const Key('wish-detail-close'));
    expect(closeButton, findsOneWidget);
    expect(
      find.descendant(
        of: closeButton,
        matching: find.byIcon(Icons.close_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: closeButton, matching: find.text('关闭')),
      findsNothing,
    );

    await tester.tap(closeButton);
    await tester.pumpAndSettle();
    expect(detailSheet, findsNothing);
  });

  testWidgets('新增心愿只显示拾入心愿匣和放弃按钮', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addWish(
      WishEntry(
        id: 'cooling-actions',
        name: '冷静中的心愿',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WishlistScreen(store: store),
      ),
    );
    await tester.pump();

    expect(find.text('拾入心愿匣'), findsOneWidget);
    expect(find.text('放弃'), findsOneWidget);
    expect(find.text('提前决定'), findsNothing);
    expect(find.text('再冷静 7 天'), findsNothing);
    expect(find.text('仍想要'), findsNothing);
  });

  testWidgets('超过计划冷静期后显示实际经过天数', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addWish(
      WishEntry(
        id: 'overdue-cooling',
        name: '超过计划的心愿',
        createdAt: DateTime.now()
            .subtract(const Duration(days: 2, hours: 2))
            .toIso8601String(),
        coolingDays: 1,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WishlistScreen(store: store),
      ),
    );
    await tester.pump();

    expect(find.text('实际已冷静 2 天 · 可以决定了'), findsOneWidget);

    await tester.tap(find.text('超过计划的心愿'));
    await tester.pumpAndSettle();

    expect(find.text('实际 2 天'), findsOneWidget);
    expect(find.text('计划冷静 1 天，目前已超过 1 天。'), findsOneWidget);
  });

  testWidgets('新增心愿确认后可拾入心愿匣并预填物品', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addWish(
      WishEntry(
        id: 'wanted-for-item',
        name: '掌上游戏机',
        category: 'digital',
        expectedPrice: 2345,
        reason: '通勤时玩',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WishlistScreen(store: store),
      ),
    );
    await tester.pump();

    expect(find.text('编辑'), findsNothing);
    expect(find.text('拾入心愿匣'), findsOneWidget);
    expect(find.text('放弃'), findsOneWidget);
    expect(
      find.descendant(
        of: find.widgetWithText(FilledButton, '拾入心愿匣'),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );

    await tester.tap(find.text('拾入心愿匣'));
    await tester.pumpAndSettle();

    expect(find.text('拾入心愿匣？'), findsOneWidget);
    expect(find.text('拾入心愿匣后，该心愿状态将变为“已达成”，是否确认操作？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(store.wishlist.single.status, 'cooling');

    await tester.tap(find.text('拾入心愿匣'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();

    expect(find.text('拾一件'), findsOneWidget);
    expect(find.text('掌上游戏机'), findsOneWidget);
    expect(find.text('2,345'), findsOneWidget);

    final addItemButton = find.text('放入匣中');
    await tester.ensureVisible(addItemButton);
    await tester.pumpAndSettle();
    await tester.tap(addItemButton);
    await tester.pumpAndSettle();

    expect(store.items.single.name, '掌上游戏机');
    expect(store.items.single.category, 'digital');
    expect(store.items.single.purchasePrice, 2345);
    expect(store.wishlist.single.status, 'achieved');
    expect(store.wishlist.single.achievedAt, isNotEmpty);
  });

  testWidgets('确认想要的心愿可以放弃', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addWish(
      WishEntry(
        id: 'wanted-abandon',
        name: '准备放弃的心愿',
        createdAt: DateTime.now().toIso8601String(),
        status: 'wanted',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WishlistScreen(store: store),
      ),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '已决定'));
    await tester.pump();

    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();

    expect(find.text('放弃这个心愿？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(store.wishlist.single.status, 'wanted');

    await tester.tap(find.text('放弃'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '放弃'));
    await tester.pumpAndSettle();

    expect(store.wishlist.single.status, 'abandoned');
    expect(store.wishlist.single.achievedAt, isEmpty);
    expect(find.text('编辑'), findsNothing);
    expect(find.text('拾入心愿匣'), findsNothing);
    expect(find.text('放弃'), findsNothing);
  });

  testWidgets('已完成心愿在详情中只提供删除操作', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addWish(
      WishEntry(
        id: 'achieved-readonly',
        name: '已经完成的心愿',
        expectedPrice: 3200,
        createdAt: DateTime.now().toIso8601String(),
        status: 'achieved',
        achievedAt: '2026-11-10T13:26:00.000',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WishlistScreen(store: store),
      ),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '已决定'));
    await tester.pump();
    expect(find.text('数码产品 · 达成于 2026-11-10 13:26'), findsOneWidget);
    expect(find.text('数码产品 · 预计 ¥3,200'), findsNothing);
    await tester.tap(find.text('已经完成的心愿'));
    await tester.pumpAndSettle();

    expect(find.text('心愿详情'), findsNothing);
    expect(find.text('编辑心愿'), findsNothing);
    expect(find.text('放弃'), findsNothing);
    expect(find.text('拾入心愿匣'), findsNothing);
    expect(find.text('达成时间'), findsOneWidget);
    expect(find.text('2026-11-10 13:26'), findsOneWidget);
    expect(find.text('预计价格'), findsNothing);
    expect(find.text('删除'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets('跨月未决定心愿始终显示且顶部在双倍字号下不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    final now = DateTime.now();
    await store.addWish(
      WishEntry(
        id: 'old-cooling',
        name: '上个月仍未决定的心愿',
        expectedPrice: 1999,
        coolingDays: 30,
        createdAt: DateTime(now.year, now.month - 1, 15).toIso8601String(),
        status: 'cooling',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: WishlistScreen(store: store),
      ),
    );
    await tester.pump();

    expect(find.text('上个月仍未决定的心愿'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
