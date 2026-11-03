import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/models.dart';
import 'package:hsgx/widgets.dart';

void main() {
  test('物品金额与日均成本按数量计算', () {
    final item = InventoryItem(
      id: 'test',
      name: '测试物品',
      purchasePrice: 1000,
      currentValue: 600,
      purchaseDate: formatDate(
        DateTime.now().subtract(const Duration(days: 9)),
      ),
      createdAt: DateTime.now().toIso8601String(),
      quantity: 2,
    );

    expect(item.purchaseTotal, 2000);
    expect(item.currentTotal, 1200);
    expect(item.ownedDays, 10);
    expect(item.ownedDailyCost, 100);
  });

  test('物品序列化后保留标签与状态历史', () {
    final item = InventoryItem(
      id: 'round-trip',
      name: '耳机',
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      tags: const ['通勤', '常用'],
      statusHistory: [
        StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
      ],
    );

    final restored = InventoryItem.fromJson(item.toJson());
    expect(restored.name, '耳机');
    expect(restored.tags, ['通勤', '常用']);
    expect(restored.statusHistory.single.status, 'inuse');
  });

  test('物品序列化后保留多图、币种、关联和完整生命周期信息', () {
    final item = InventoryItem(
      id: 'full-round-trip',
      name: '相机组合',
      purchaseCurrency: 'USD',
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      imagePaths: const ['/a.jpg', '/b.jpg'],
      relatedItemIds: const ['lens'],
      idleReason: '暂时收纳',
      repairPlatform: '品牌官方',
      repairDays: 7,
      repairContactName: '维修员',
      repairContactPhone: '13800138000',
      disposalMethod: '转卖',
      disposalPlatform: '闲鱼',
      disposalContact: '买家',
      disposalPrice: 500,
      processDate: '2026-10-01',
    );

    final restored = InventoryItem.fromJson(item.toJson());
    expect(restored.purchaseCurrency, 'USD');
    expect(restored.currencySymbol, '\$');
    expect(restored.imagePaths, ['/a.jpg', '/b.jpg']);
    expect(restored.relatedItemIds, ['lens']);
    expect(restored.repairPlatform, '品牌官方');
    expect(restored.repairDays, 7);
    expect(restored.disposalPlatform, '闲鱼');
    expect(restored.disposalContact, '买家');
    expect(restored.processDate, '2026-10-01');
  });

  testWidgets('下拉字段从底部弹出并回传选择结果', (tester) async {
    String selected = 'digital';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: BottomSelectField<String>(
              label: '生活分类',
              value: selected,
              options: const [
                BottomSelectOption(value: 'digital', label: '数码产品'),
                BottomSelectOption(value: 'clothing', label: '服饰箱包'),
              ],
              onChanged: (value) => selected = value ?? '',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(BottomSelectField<String>));
    await tester.pumpAndSettle();

    expect(find.text('生活分类'), findsWidgets);
    expect(find.text('服饰箱包'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.tap(find.text('服饰箱包'));
    await tester.pumpAndSettle();

    expect(selected, 'clothing');
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('空状态在左对齐容器中仍占满可用宽度', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmptyState(
                  title: '心愿匣还是空的',
                  description: '把想买的东西先放进来，让时间帮你判断。',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final screenWidth = tester.getSize(find.byType(Scaffold)).width;
    final emptyStateWidth = tester.getSize(find.byType(EmptyState)).width;
    expect(emptyStateWidth, screenWidth - 40);
  });
}
