import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/domain/insights_summary.dart';
import 'package:hsgx/models.dart';

InventoryItem _item({
  required String id,
  required String purchaseDate,
  String status = 'inuse',
  String category = 'digital',
  String subcategory = '',
  double currentValue = 100,
  String usageMode = 'auto',
  List<StatusEvent> statusHistory = const [],
}) {
  return InventoryItem(
    id: id,
    name: '物品 $id',
    purchaseDate: purchaseDate,
    createdAt: '${purchaseDate}T08:00:00.000',
    status: status,
    category: category,
    subcategory: subcategory,
    currentValue: currentValue,
    purchasePrice: currentValue,
    usageMode: usageMode,
    statusHistory: statusHistory,
  );
}

void main() {
  final now = DateTime(2026, 11, 5);

  test('近 30 天只统计本期购入，但使用率基于全部生活物品', () {
    final snapshot = InsightsSnapshot.build(
      [
        _item(
          id: 'recent',
          purchaseDate: '2026-10-20',
          statusHistory: [
            StatusEvent(status: 'inuse', at: '2026-10-20T08:00:00.000'),
          ],
        ),
        _item(
          id: 'older',
          purchaseDate: '2025-01-01',
          statusHistory: [
            StatusEvent(status: 'inuse', at: '2025-01-01T08:00:00.000'),
          ],
        ),
      ],
      period: InsightsPeriod.last30,
      now: now,
    );

    expect(snapshot.activeCount, 2);
    expect(snapshot.periodPurchaseCount, 1);
    expect(snapshot.periodPurchaseAmount, 100);
    expect(snapshot.usageRate, 1);
  });

  test('长期闲置优先进入值得处理的提醒', () {
    final snapshot = InsightsSnapshot.build(
      [
        _item(
          id: 'idle',
          purchaseDate: '2025-01-01',
          status: 'idle',
          category: 'furniture',
          subcategory: '灯具',
          currentValue: 2000,
          statusHistory: [
            StatusEvent(status: 'inuse', at: '2025-01-01T08:00:00.000'),
            StatusEvent(status: 'idle', at: '2026-06-01T08:00:00.000'),
          ],
        ),
        _item(
          id: 'duplicate-1',
          purchaseDate: '2026-09-01',
          category: 'beauty',
          subcategory: '香氛',
        ),
        _item(
          id: 'duplicate-2',
          purchaseDate: '2026-09-02',
          category: 'beauty',
          subcategory: '香氛',
        ),
        _item(
          id: 'duplicate-3',
          purchaseDate: '2026-09-03',
          category: 'beauty',
          subcategory: '香氛',
        ),
      ],
      period: InsightsPeriod.sixMonths,
      now: now,
    );

    expect(snapshot.alerts.first.action, InsightAlertAction.recovery);
    expect(snapshot.alerts.first.itemId, 'idle');
    expect(snapshot.alerts.first.message, contains('已闲置'));
    expect(
      snapshot.alerts.map((alert) => alert.action),
      contains(InsightAlertAction.duplicate),
    );
  });

  test('物品少于三件时收敛详细分析', () {
    final twoItems = InsightsSnapshot.build(
      [
        _item(id: 'a', purchaseDate: '2026-10-01'),
        _item(id: 'b', purchaseDate: '2026-10-02'),
      ],
      period: InsightsPeriod.last30,
      now: now,
    );
    final threeItems = InsightsSnapshot.build(
      [
        _item(id: 'a', purchaseDate: '2026-10-01'),
        _item(id: 'b', purchaseDate: '2026-10-02'),
        _item(id: 'c', purchaseDate: '2026-10-03'),
      ],
      period: InsightsPeriod.last30,
      now: now,
    );

    expect(twoItems.hasEnoughData, isFalse);
    expect(threeItems.hasEnoughData, isTrue);
  });

  test('已处理物品不计入当前分类资产', () {
    final snapshot = InsightsSnapshot.build(
      [
        _item(id: 'active', purchaseDate: '2026-01-01', currentValue: 100),
        _item(
          id: 'processed',
          purchaseDate: '2026-01-01',
          status: 'processed',
          category: 'furniture',
          currentValue: 500,
        ),
      ],
      period: InsightsPeriod.last30,
      now: now,
    );

    expect(snapshot.currentValue, 100);
    expect(snapshot.categories.single.category.id, 'digital');
    expect(snapshot.categories.single.value, 100);
  });

  test('很久以前结束的保修不再进入当前提醒', () {
    final item = InventoryItem(
      id: 'old-warranty',
      name: '旧设备',
      purchaseDate: '2020-01-01',
      createdAt: '2020-01-01T00:00:00.000',
      warrantyEndDate: '2021-01-01',
    );

    final snapshot = InsightsSnapshot.build(
      [item],
      period: InsightsPeriod.last30,
      now: now,
    );

    expect(snapshot.alerts.any((alert) => alert.label == '期限已结束'), isFalse);
  });
}
