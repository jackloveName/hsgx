import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/domain/home_insight.dart';
import 'package:hsgx/models.dart';

InventoryItem _item({
  String id = 'item',
  String status = 'inuse',
  double purchasePrice = 100,
  double currentValue = 80,
  String warrantyEndDate = '',
  String netWeight = '',
  String remainingNetWeight = '',
  String usageMode = 'auto',
  int manualUsageCount = 0,
  List<String> usageRecords = const [],
}) {
  return InventoryItem(
    id: id,
    name: '物品 $id',
    status: status,
    purchasePrice: purchasePrice,
    currentValue: currentValue,
    purchaseDate: '2025-01-01',
    createdAt: '2025-01-01T00:00:00.000',
    warrantyEndDate: warrantyEndDate,
    netWeight: netWeight,
    remainingNetWeight: remainingNetWeight,
    usageMode: usageMode,
    manualUsageCount: manualUsageCount,
    usageRecords: usageRecords,
    statusHistory: [
      StatusEvent(status: 'inuse', at: '2025-01-01T00:00:00.000'),
    ],
  );
}

void main() {
  final now = DateTime(2026, 11, 3);

  test('临近期限的优先级高于闲置和心愿', () {
    final result = buildHomeInsight(
      [
        _item(id: 'warranty', warrantyEndDate: '2026-11-08'),
        _item(id: 'idle', status: 'idle'),
      ],
      [WishEntry(id: 'wish', name: '心愿', createdAt: '2026-10-20T00:00:00.000')],
      now: now,
    );

    expect(result.type, 'warranty');
    expect(result.action, 'detail');
    expect(result.itemId, 'warranty');
  });

  test('低库存会在普通闲置之前提醒', () {
    final result = buildHomeInsight(
      [
        _item(id: 'stock', netWeight: '100g', remainingNetWeight: '12g'),
        _item(id: 'idle', status: 'idle'),
      ],
      const [],
      now: now,
    );

    expect(result.type, 'stock');
    expect(result.itemId, 'stock');
  });

  test('长期未使用的手动物品会生成使用提醒', () {
    final result = buildHomeInsight(
      [
        _item(
          id: 'unused',
          usageMode: 'manual',
          currentValue: 3000,
          usageRecords: const ['2026-01-01T00:00:00.000'],
        ),
      ],
      const [],
      now: now,
    );

    expect(result.type, 'ignored');
    expect(result.message, contains('没有使用'));
  });
}
