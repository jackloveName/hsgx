import '../models.dart';

String? recentUseText(InventoryItem item, {DateTime? now}) {
  final lastUsed = item.lastUsedAtAsOf(now ?? DateTime.now());
  return lastUsed == null ? null : '最近使用：${formatDate(lastUsed)}';
}

String? itemStatusDurationText(InventoryItem item) {
  return switch (item.status) {
    'idle' => '已闲置 ${item.idleDays} 天',
    'repairing' => item.repairDays > 0 ? '预计维修 ${item.repairDays} 天' : '维修中',
    'retired' => '已退役 ${item.retiredDays} 天',
    _ => null,
  };
}

String itemBrowseContext(InventoryItem item, {bool includeUsageCost = true}) {
  return switch (item.status) {
    'idle' || 'repairing' || 'retired' => itemStatusDurationText(item)!,
    _ when item.usageMode == 'manual' => '已记录 ${item.manualUsageCount} 次',
    _ when includeUsageCost =>
      '已使用 ${item.usageDays} 天 · '
          '${item.currencySymbol}${formatMoney(item.usageAverageCost)}/天',
    _ => '已使用 ${item.usageDays} 天',
  };
}
