import 'dart:math' as math;

import '../models.dart';

enum InsightsPeriod {
  last30(days: 30, label: '近 30 天', comparisonLabel: '前 30 天'),
  sixMonths(days: 183, label: '近 6 个月', comparisonLabel: '前 6 个月'),
  all(days: null, label: '全部', comparisonLabel: '上一周期');

  const InsightsPeriod({
    required this.days,
    required this.label,
    required this.comparisonLabel,
  });

  final int? days;
  final String label;
  final String comparisonLabel;
}

enum InsightAlertAction {
  item,
  recovery,
  warranty,
  stock,
  idle,
  unused,
  target,
  expiring,
  expired,
  lowStock,
  duplicate,
}

class InsightAlert {
  const InsightAlert({
    required this.title,
    required this.message,
    required this.label,
    required this.action,
    this.itemId,
    this.category,
    this.subcategory,
  });

  final String title;
  final String message;
  final String label;
  final InsightAlertAction action;
  final String? itemId;
  final String? category;
  final String? subcategory;
}

class InsightCategoryMetric {
  const InsightCategoryMetric({
    required this.category,
    required this.value,
    required this.ratio,
    required this.dailyCost,
  });

  final ItemCategory category;
  final double value;
  final double ratio;
  final double dailyCost;
}

class InsightTrendPoint {
  const InsightTrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class InsightsSnapshot {
  const InsightsSnapshot({
    required this.period,
    required this.totalCount,
    required this.activeCount,
    required this.usedCount,
    required this.inUseCount,
    required this.idleCount,
    required this.repairingCount,
    required this.usageRate,
    required this.periodUsageDays,
    required this.currentValue,
    required this.idleValue,
    required this.periodPurchaseAmount,
    required this.periodPurchaseCount,
    required this.previousPurchaseAmount,
    required this.purchaseChange,
    required this.actualAutoDailyCost,
    required this.targetAutoDailyCost,
    required this.foreignCurrencyItemCount,
    required this.categories,
    required this.holdingCounts,
    required this.purchaseTrend,
    required this.alerts,
  });

  final InsightsPeriod period;
  final int totalCount;
  final int activeCount;
  final int usedCount;
  final int inUseCount;
  final int idleCount;
  final int repairingCount;
  final double usageRate;
  final int periodUsageDays;
  final double currentValue;
  final double idleValue;
  final double periodPurchaseAmount;
  final int periodPurchaseCount;
  final double previousPurchaseAmount;
  final double? purchaseChange;
  final double actualAutoDailyCost;
  final double targetAutoDailyCost;
  final int foreignCurrencyItemCount;
  final List<InsightCategoryMetric> categories;
  final List<int> holdingCounts;
  final List<InsightTrendPoint> purchaseTrend;
  final List<InsightAlert> alerts;

  bool get hasEnoughData => totalCount >= 3 || activeCount >= 3;

  factory InsightsSnapshot.build(
    List<InventoryItem> items, {
    required InsightsPeriod period,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final active = items.where((item) => item.isActive).toList();
    final activeBase = active
        .where((item) => item.canAggregateInBaseCurrency)
        .toList();
    final foreignCurrencyItemCount = active.length - activeBase.length;
    final usageByItem = <String, int>{
      for (final item in active)
        item.id: period.days == null
            ? item.usageDaysAsOf(today)
            : item.usageDaysInLastDays(period.days!, now: today),
    };
    final usedCount = usageByItem.values.where((days) => days > 0).length;
    final periodUsageDays = usageByItem.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final idleItems = activeBase
        .where((item) => item.status == 'idle')
        .toList();
    final idleValue = idleItems.fold<double>(
      0,
      (sum, item) => sum + item.currentTotal,
    );
    final currentValue = activeBase.fold<double>(
      0,
      (sum, item) => sum + item.currentTotal,
    );

    final range = _purchaseRange(period, today);
    final previousRange = _previousPurchaseRange(period, range);
    final periodPurchases = items.where((item) {
      final date = parseDate(item.purchaseDate);
      return date != null && range.contains(date);
    }).toList();
    final previousPurchases = previousRange == null
        ? const <InventoryItem>[]
        : items.where((item) {
            final date = parseDate(item.purchaseDate);
            return date != null && previousRange.contains(date);
          }).toList();
    final periodAmount = periodPurchases
        .where((item) => item.canAggregateInBaseCurrency)
        .fold<double>(0, (sum, item) => sum + item.purchaseTotal);
    final previousAmount = previousPurchases
        .where((item) => item.canAggregateInBaseCurrency)
        .fold<double>(0, (sum, item) => sum + item.purchaseTotal);
    final change = previousRange == null || previousAmount == 0
        ? null
        : (periodAmount - previousAmount) / previousAmount;

    final usedItems = activeBase.where(
      (item) => (usageByItem[item.id] ?? 0) > 0,
    );
    final usedPurchaseTotal = usedItems.fold<double>(
      0,
      (sum, item) => sum + item.purchaseTotal,
    );
    final dailyUsageItems = usedItems.where(
      (item) => item.usageMode != 'manual',
    );
    final allUsageDays = dailyUsageItems.fold<int>(
      0,
      (sum, item) => sum + item.usageDays,
    );
    final targetItems = dailyUsageItems.where(
      (item) => item.effectiveTargetValue > 0,
    );
    final targetPurchaseTotal = targetItems.fold<double>(
      0,
      (sum, item) => sum + item.purchaseTotal,
    );
    final targetDays = targetItems.fold<int>(
      0,
      (sum, item) => sum + item.effectiveTargetValue,
    );

    final categoryValues = <InsightCategoryMetric>[];
    for (final category in itemCategories) {
      final categoryItems = activeBase.where(
        (item) => item.category == category.id,
      );
      final value = categoryItems.fold<double>(
        0,
        (sum, item) => sum + item.currentTotal,
      );
      if (value <= 0) continue;
      categoryValues.add(
        InsightCategoryMetric(
          category: category,
          value: value,
          ratio: 0,
          dailyCost: categoryItems.fold<double>(
            0,
            (sum, item) => sum + item.ownedDailyCost,
          ),
        ),
      );
    }
    final categoryTotal = categoryValues.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );
    final categories = [
      for (final entry in categoryValues)
        InsightCategoryMetric(
          category: entry.category,
          value: entry.value,
          ratio: categoryTotal == 0 ? 0 : entry.value / categoryTotal,
          dailyCost: entry.dailyCost,
        ),
    ]..sort((a, b) => b.value.compareTo(a.value));

    final holdingCounts = List<int>.filled(5, 0);
    for (final item in items) {
      final days = item.ownedDaysAsOf(today);
      final index = switch (days) {
        < 30 => 0,
        < 180 => 1,
        < 365 => 2,
        < 1095 => 3,
        _ => 4,
      };
      holdingCounts[index] += 1;
    }

    return InsightsSnapshot(
      period: period,
      totalCount: items.length,
      activeCount: active.length,
      usedCount: usedCount,
      inUseCount: active.where((item) => item.status == 'inuse').length,
      idleCount: active.where((item) => item.status == 'idle').length,
      repairingCount: active.where((item) => item.status == 'repairing').length,
      usageRate: active.isEmpty ? 0 : usedCount / active.length,
      periodUsageDays: periodUsageDays,
      currentValue: currentValue,
      idleValue: idleValue,
      periodPurchaseAmount: periodAmount,
      periodPurchaseCount: periodPurchases.length,
      previousPurchaseAmount: previousAmount,
      purchaseChange: change,
      actualAutoDailyCost: allUsageDays == 0
          ? 0
          : usedPurchaseTotal / allUsageDays,
      targetAutoDailyCost: targetDays == 0
          ? 0
          : targetPurchaseTotal / targetDays,
      foreignCurrencyItemCount: foreignCurrencyItemCount,
      categories: categories,
      holdingCounts: holdingCounts,
      purchaseTrend: _purchaseTrend(
        items.where((item) => item.canAggregateInBaseCurrency).toList(),
        period,
        today,
      ),
      alerts: _buildAlerts(items, active, today, usageByItem),
    );
  }
}

_DateRange _purchaseRange(InsightsPeriod period, DateTime today) {
  final start = period.days == null
      ? DateTime(1900)
      : today.subtract(Duration(days: period.days! - 1));
  return _DateRange(start, today);
}

_DateRange? _previousPurchaseRange(InsightsPeriod period, _DateRange current) {
  if (period.days == null) return null;
  final end = current.start.subtract(const Duration(days: 1));
  final start = end.subtract(Duration(days: period.days! - 1));
  return _DateRange(start, end);
}

List<InsightTrendPoint> _purchaseTrend(
  List<InventoryItem> items,
  InsightsPeriod period,
  DateTime today,
) {
  final points = <InsightTrendPoint>[];
  if (period == InsightsPeriod.last30) {
    for (var index = 3; index >= 0; index--) {
      final end = today.subtract(Duration(days: index * 7));
      final start = end.subtract(const Duration(days: 6));
      final range = _DateRange(start, end);
      final value = items
          .where((item) {
            final date = parseDate(item.purchaseDate);
            return date != null && range.contains(date);
          })
          .fold<double>(0, (sum, item) => sum + item.purchaseTotal);
      points.add(
        InsightTrendPoint(label: '${end.month}/${end.day}', value: value),
      );
    }
    return points;
  }

  for (var index = 5; index >= 0; index--) {
    final month = DateTime(today.year, today.month - index);
    final value = items
        .where((item) {
          final date = parseDate(item.purchaseDate);
          return date != null &&
              date.year == month.year &&
              date.month == month.month;
        })
        .fold<double>(0, (sum, item) => sum + item.purchaseTotal);
    points.add(InsightTrendPoint(label: '${month.month}月', value: value));
  }
  return points;
}

List<InsightAlert> _buildAlerts(
  List<InventoryItem> items,
  List<InventoryItem> active,
  DateTime today,
  Map<String, int> usageByItem,
) {
  final alerts = <InsightAlert>[];
  final warranties =
      active
          .map((item) => (item: item, end: item.warrantyEnd))
          .where((entry) => entry.end != null)
          .map(
            (entry) =>
                (item: entry.item, days: entry.end!.difference(today).inDays),
          )
          .where((entry) => entry.days >= -30 && entry.days <= 30)
          .toList()
        ..sort((first, second) => first.days.compareTo(second.days));
  if (warranties.isNotEmpty) {
    final entry = warranties.first;
    alerts.add(
      InsightAlert(
        label: entry.days < 0 ? '期限已结束' : '期限将至',
        title: entry.item.name,
        message: entry.days < 0
            ? '已经超过期限 ${entry.days.abs()} 天，检查是否需要处理。'
            : '距离期限还有 ${entry.days} 天，适合现在检查。',
        action: InsightAlertAction.item,
        itemId: entry.item.id,
      ),
    );
  }

  final lowStock = active.where(_isLowStock).toList()
    ..sort((a, b) => a.remainingRatio.compareTo(b.remainingRatio));
  if (lowStock.isNotEmpty) {
    final item = lowStock.first;
    alerts.add(
      InsightAlert(
        label: '库存不足',
        title: item.name,
        message: '已经接近用完，可以提前安排补充。',
        action: InsightAlertAction.item,
        itemId: item.id,
      ),
    );
  }

  final idle =
      active
          .where((item) => item.status == 'idle' && !item.hasRecoveryPlan)
          .toList()
        ..sort((a, b) => b.idleDays.compareTo(a.idleDays));
  if (idle.isNotEmpty) {
    final item = idle.first;
    alerts.add(
      InsightAlert(
        label: '闲置待决定',
        title: item.name,
        message: '已闲置 ${item.idleDays} 天，可以重新使用或安排回血。',
        action: InsightAlertAction.recovery,
        itemId: item.id,
      ),
    );
  }

  final unused = active.where((item) {
    if (item.usageMode != 'manual' || item.ownedDaysAsOf(today) < 45) {
      return false;
    }
    final lastUsed = item.lastUsedAt;
    return lastUsed == null ||
        today
                .difference(
                  DateTime(lastUsed.year, lastUsed.month, lastUsed.day),
                )
                .inDays >=
            60;
  }).toList()..sort((a, b) => b.currentTotal.compareTo(a.currentTotal));
  if (unused.isNotEmpty) {
    final item = unused.first;
    alerts.add(
      InsightAlert(
        label: '高价值未使用',
        title: item.name,
        message: item.lastUsedAt == null
            ? '还没有使用记录，今天可以重新用一次。'
            : '已经超过 60 天没有使用，值得重新评估。',
        action: InsightAlertAction.item,
        itemId: item.id,
      ),
    );
  }

  final groups = <String, List<InventoryItem>>{};
  for (final item in items) {
    if (item.subcategory.trim().isEmpty) continue;
    groups
        .putIfAbsent('${item.category}::${item.subcategory}', () => [])
        .add(item);
  }
  final duplicates = groups.values.where((group) => group.length >= 3).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  if (duplicates.isNotEmpty) {
    final group = duplicates.first;
    alerts.add(
      InsightAlert(
        label: '重复购买',
        title: '${group.first.subcategory}已有 ${group.length} 件',
        message: '同类物品数量较多，可以检查是否还有重复需求。',
        action: InsightAlertAction.duplicate,
        category: group.first.category,
        subcategory: group.first.subcategory,
      ),
    );
  }

  if (alerts.length < 3) {
    final withoutTarget =
        active
            .where(
              (item) =>
                  item.effectiveTargetValue == 0 &&
                  (usageByItem[item.id] ?? 0) > 0,
            )
            .toList()
          ..sort((a, b) => b.currentTotal.compareTo(a.currentTotal));
    if (withoutTarget.isNotEmpty) {
      final item = withoutTarget.first;
      alerts.add(
        InsightAlert(
          label: '建立使用目标',
          title: item.name,
          message: item.usageMode == 'manual'
              ? '设置目标使用次数后，可以判断每次使用是否真正花得值。'
              : '设置目标使用天数后，可以判断日均成本是否符合预期。',
          action: InsightAlertAction.item,
          itemId: item.id,
        ),
      );
    }
  }

  return alerts;
}

bool _isLowStock(InventoryItem item) {
  if (item.status != 'inuse') return false;
  return item.remainingRatio <= 0.2;
}

extension on InventoryItem {
  double get remainingRatio {
    final initial = double.tryParse(
      netWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final remaining = double.tryParse(
      remainingNetWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (initial == null || remaining == null || initial <= 0) return 1;
    return math.max(0, remaining / initial);
  }
}

class _DateRange {
  const _DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}
