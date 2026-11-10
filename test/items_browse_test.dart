import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/app_store.dart';
import 'package:hsgx/domain/items_browse.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/screens/items_screen.dart';
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

InventoryItem _item({
  required String id,
  required String location,
  double currentValue = 100,
  String createdAt = '2026-01-01T00:00:00.000',
  String category = 'digital',
  String usageMode = 'auto',
  int manualUsageCount = 0,
  List<String> usageRecords = const [],
}) {
  return InventoryItem(
    id: id,
    name: '物品 $id',
    category: category,
    purchaseDate: '2026-01-01',
    createdAt: createdAt,
    currentValue: currentValue,
    purchasePrice: currentValue,
    usageMode: usageMode,
    manualUsageCount: manualUsageCount,
    usageRecords: usageRecords,
    storageLocation: location,
    statusHistory: [
      StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
    ],
  );
}

void main() {
  test('浏览摘要汇总当前筛选结果的件数、估值和使用天数', () {
    final summary = ItemsBrowseSummary.fromItems([
      _item(id: 'one', location: '客厅', currentValue: 200),
      _item(id: 'two', location: '卧室', currentValue: 300),
    ]);

    expect(summary.count, 2);
    expect(summary.currentValue, 500);
    expect(summary.usageDays, greaterThanOrEqualTo(0));
  });

  test('收纳视图按位置分组，并把未设置位置放在最后', () {
    final groups = groupItemsByLocation([
      _item(id: 'none', location: ''),
      _item(
        id: 'bedroom-old',
        location: '卧室',
        createdAt: '2026-01-01T00:00:00.000',
      ),
      _item(id: 'living', location: '客厅', currentValue: 200),
      _item(
        id: 'bedroom-new',
        location: '卧室',
        createdAt: '2026-02-01T00:00:00.000',
      ),
    ]);

    expect(groups.map((group) => group.location), ['卧室', '客厅', '未设置位置']);
    expect(groups[0].items.map((item) => item.id), [
      'bedroom-new',
      'bedroom-old',
    ]);
    expect(groups[0].currentValue, 200);
  });

  test('首页最近使用只返回按最后使用时间排序的前五条', () {
    final now = DateTime(2026, 11, 7);
    final items = [
      for (var index = 0; index < 7; index++)
        _item(
          id: '$index',
          location: '书房',
          usageMode: 'manual',
          usageRecords: [DateTime(2026, 11, index + 1).toIso8601String()],
        ),
    ];

    final recent = recentItemsForHome(items, now: now);

    expect(recent, hasLength(5));
    expect(recent.map((item) => item.id), ['6', '5', '4', '3', '2']);
  });

  testWidgets('物品页不再显示状态筛选', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: ItemsScreen()),
      ),
    );
    await tester.pump();

    for (final label in ['全部', '使用中', '闲置', '维修中', '已处理', '已退役', '筛选']) {
      expect(find.text(label), findsNothing);
    }
    expect(find.text('陈列'), findsOneWidget);
    expect(find.text('台账'), findsOneWidget);
    expect(find.text('收纳'), findsOneWidget);
    expect(find.text('搜索物品名称'), findsOneWidget);
  });

  testWidgets('物品页搜索只匹配物品名称', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      _item(
        id: 'headphones',
        location: '书房',
      ).copyWith(name: '降噪耳机', tags: const ['通勤']),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: ItemsScreen(store: store)),
      ),
    );
    await tester.pump();

    final search = find.byType(TextField);
    await tester.enterText(search, '数码产品');
    await tester.pump();
    expect(find.text('降噪耳机'), findsNothing);

    await tester.enterText(search, '通勤');
    await tester.pump();
    expect(find.text('降噪耳机'), findsNothing);

    await tester.enterText(search, '降噪');
    await tester.pump();
    expect(find.text('降噪耳机'), findsOneWidget);
  });

  testWidgets('陈列模式显示分类和手动计次调节器', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      _item(
        id: 'manual',
        location: '',
        category: 'clothing',
        usageMode: 'manual',
        manualUsageCount: 3,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: ItemsScreen(store: store)),
      ),
    );
    await tester.pump();

    expect(find.textContaining('已记录'), findsNothing);
    expect(find.text('服饰箱包'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('¥33.33/次'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('¥33.33/次')).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('gallery-manual-stepper-manual')))
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const Key('gallery-manual-stepper-manual')))
          .dx,
      lessThan(tester.getCenter(find.text('物品 manual')).dx),
    );
    expect(
      tester.getTopRight(find.text('¥33.33/次')).dx,
      greaterThan(tester.getCenter(find.text('物品 manual')).dx),
    );

    await tester.tap(find.byKey(const Key('manual-usage-increment-manual')));
    await tester.pumpAndSettle();

    expect(store.itemById('manual')!.manualUsageCount, 4);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('¥25/次'), findsOneWidget);

    await tester.tap(find.byKey(const Key('manual-usage-decrement-manual')));
    await tester.pumpAndSettle();

    expect(store.itemById('manual')!.manualUsageCount, 3);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('陈列不显示位置，台账显示位置、分类和最近使用', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(_item(id: 'located', location: '玄关'));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: ItemsScreen(store: store)),
      ),
    );
    await tester.pump();

    expect(find.text('玄关'), findsNothing);
    expect(find.text('数码产品'), findsOneWidget);
    expect(find.textContaining('/天'), findsOneWidget);

    await tester.tap(find.text('台账'));
    await tester.pumpAndSettle();

    expect(find.text('未设置位置'), findsNothing);
    expect(find.text('数码产品 · 玄关'), findsOneWidget);
    expect(find.textContaining('已使用'), findsOneWidget);
    expect(find.textContaining('最近使用：'), findsOneWidget);
    expect(find.text('¥100'), findsNothing);
    expect(
      tester.getTopLeft(find.textContaining('/天')).dx,
      greaterThan(tester.getTopLeft(find.textContaining('已使用')).dx),
    );

    await tester.tap(find.text('收纳'));
    await tester.pumpAndSettle();
    expect(find.text('数码产品'), findsOneWidget);
    expect(find.textContaining('最近使用：'), findsOneWidget);
    expect(
      tester.getTopLeft(find.textContaining('/天')).dx,
      greaterThan(tester.getTopLeft(find.text('物品 located')).dx),
    );
  });

  testWidgets('台账和收纳展示状态、计次、成本并隐藏多余信息', (tester) async {
    final store = AppStore(storage: _MemoryStorage());
    await store.load();
    await store.addItem(
      _item(
        id: 'manual',
        location: '客厅',
        category: 'clothing',
        usageMode: 'manual',
        manualUsageCount: 3,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: ItemsScreen(store: store)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('台账'));
    await tester.pumpAndSettle();

    expect(find.text('服饰箱包 · 客厅'), findsOneWidget);
    expect(find.textContaining('已记录'), findsNothing);
    expect(find.text('¥33.33/次'), findsOneWidget);
    expect(find.textContaining('最近使用：'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(
      tester.getTopLeft(find.text('使用中')).dx,
      lessThan(tester.getTopLeft(find.text('物品 manual')).dx),
    );
    expect(
      tester
          .getBottomLeft(find.byKey(const Key('ledger-usage-cost-manual')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('manual-usage-increment-manual')))
            .dy,
      ),
    );
    expect(
      tester.getTopRight(find.text('¥33.33/次')).dx,
      greaterThan(tester.getCenter(find.text('物品 manual')).dx),
    );

    await tester.tap(find.byKey(const Key('manual-usage-increment-manual')));
    await tester.pumpAndSettle();
    expect(store.itemById('manual')!.manualUsageCount, 4);
    expect(find.text('¥25/次'), findsOneWidget);

    await tester.tap(find.text('收纳'));
    await tester.pumpAndSettle();

    expect(find.text('客厅'), findsOneWidget);
    expect(find.text('1 件'), findsOneWidget);
    expect(find.text('¥100'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.text('¥25/次'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('服饰箱包'), findsOneWidget);
    expect(find.textContaining('最近使用：'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('¥25/次')).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const Key('location-manual-stepper-manual')))
            .dy,
      ),
    );
    expect(
      tester.getTopRight(find.text('¥25/次')).dx,
      greaterThan(tester.getCenter(find.text('物品 manual')).dx),
    );
    expect(
      tester.getTopLeft(find.text('使用中')).dx,
      lessThan(tester.getTopLeft(find.text('物品 manual')).dx),
    );

    await tester.tap(find.byKey(const Key('manual-usage-decrement-manual')));
    await tester.pumpAndSettle();
    expect(store.itemById('manual')!.manualUsageCount, 3);
    expect(find.text('¥33.33/次'), findsOneWidget);
  });
}
