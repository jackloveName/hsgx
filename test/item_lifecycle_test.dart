import 'package:flutter_test/flutter_test.dart';
import 'package:hsgx/models.dart';

void main() {
  InventoryItem itemWithHistory({
    required String status,
    required List<StatusEvent> history,
    String processDate = '',
  }) {
    return InventoryItem(
      id: 'lifecycle',
      name: '生命周期测试',
      purchasePrice: 1000,
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      status: status,
      statusHistory: history,
      processDate: processDate,
    );
  }

  test('闲置期间仍计入拥有天数，但不计入使用天数', () {
    final item = itemWithHistory(
      status: 'idle',
      history: [
        StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
        StatusEvent(status: 'idle', at: '2026-01-11T00:00:00.000'),
      ],
    );
    final now = DateTime(2026, 1, 31);

    expect(item.ownedDaysAsOf(now), 31);
    expect(item.usageDaysAsOf(now), 10);
    expect(item.idleDaysAsOf(now), 21);
  });

  test('多次使用区间只累计使用中的日期', () {
    final item = itemWithHistory(
      status: 'inuse',
      history: [
        StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
        StatusEvent(status: 'idle', at: '2026-01-11T00:00:00.000'),
        StatusEvent(status: 'inuse', at: '2026-01-21T00:00:00.000'),
      ],
    );
    final now = DateTime(2026, 1, 31);

    expect(item.ownedDaysAsOf(now), 31);
    expect(item.usageDaysAsOf(now), 21);
    expect(item.usageIntervalsAsOf(now), hasLength(2));
  });

  test('维修期间从自动使用天数中扣除', () {
    final item = itemWithHistory(
      status: 'inuse',
      history: [
        StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
        StatusEvent(status: 'repairing', at: '2026-01-11T00:00:00.000'),
        StatusEvent(status: 'inuse', at: '2026-01-21T00:00:00.000'),
      ],
    );

    expect(item.usageDaysAsOf(DateTime(2026, 1, 31)), 21);
  });

  test('处理后的拥有天数和使用天数在完成日停止', () {
    final item = itemWithHistory(
      status: 'processed',
      processDate: '2026-01-16',
      history: [
        StatusEvent(status: 'inuse', at: '2026-01-01T00:00:00.000'),
        StatusEvent(status: 'processed', at: '2026-01-16T00:00:00.000'),
      ],
    );
    final now = DateTime(2026, 2, 1);

    expect(item.ownedDaysAsOf(now), 16);
    expect(item.usageDaysAsOf(now), 15);
  });

  test('手动记录模式不按日期区间计算使用天数', () {
    final item = InventoryItem(
      id: 'manual',
      name: '手动记录',
      purchaseDate: '2026-01-01',
      createdAt: '2026-01-01T00:00:00.000',
      usageMode: 'manual',
      manualUsageCount: 42,
    );

    expect(item.usageDaysAsOf(DateTime(2026, 12, 31)), 42);
  });
}
