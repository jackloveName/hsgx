import '../models.dart';

enum ItemsBrowseMode {
  gallery(label: '陈列', iconName: 'gallery'),
  ledger(label: '台账', iconName: 'ledger'),
  location(label: '收纳', iconName: 'location');

  const ItemsBrowseMode({required this.label, required this.iconName});

  final String label;
  final String iconName;
}

class ItemsBrowseSummary {
  const ItemsBrowseSummary({
    required this.count,
    required this.currentValue,
    required this.usageDays,
  });

  final int count;
  final double currentValue;
  final int usageDays;

  factory ItemsBrowseSummary.fromItems(List<InventoryItem> items) {
    return ItemsBrowseSummary(
      count: items.length,
      currentValue: items
          .where((item) => item.canAggregateInBaseCurrency)
          .fold<double>(0, (sum, item) => sum + item.currentTotal),
      usageDays: items.fold<int>(
        0,
        (sum, item) => sum + item.usageDaysInLastDays(30),
      ),
    );
  }
}

class LocationGroup {
  const LocationGroup({
    required this.location,
    required this.items,
    required this.currentValue,
  });

  final String location;
  final List<InventoryItem> items;
  final double currentValue;
}

List<InventoryItem> recentItemsForHome(
  List<InventoryItem> items, {
  int limit = 5,
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final active = items.where((item) => item.isActive).toList();
  final source = active.isEmpty ? List<InventoryItem>.from(items) : active;
  source.sort((first, second) {
    final firstUsed = first.lastUsedAtAsOf(current);
    final secondUsed = second.lastUsedAtAsOf(current);
    if (firstUsed != null || secondUsed != null) {
      if (firstUsed == null) return 1;
      if (secondUsed == null) return -1;
      final byUse = secondUsed.compareTo(firstUsed);
      if (byUse != 0) return byUse;
    }
    return second.createdAt.compareTo(first.createdAt);
  });
  return source.take(limit).toList();
}

List<LocationGroup> groupItemsByLocation(List<InventoryItem> items) {
  final grouped = <String, List<InventoryItem>>{};
  for (final item in items) {
    final location = item.storageLocation.trim().isEmpty
        ? '未设置位置'
        : item.storageLocation.trim();
    (grouped[location] ??= []).add(item);
  }
  final names = grouped.keys.toList()
    ..sort((first, second) {
      if (first == '未设置位置') return 1;
      if (second == '未设置位置') return -1;
      final byCount = grouped[second]!.length.compareTo(grouped[first]!.length);
      if (byCount != 0) return byCount;
      final firstValue = grouped[first]!
          .where((item) => item.canAggregateInBaseCurrency)
          .fold<double>(0, (sum, item) => sum + item.currentTotal);
      final secondValue = grouped[second]!
          .where((item) => item.canAggregateInBaseCurrency)
          .fold<double>(0, (sum, item) => sum + item.currentTotal);
      return secondValue.compareTo(firstValue);
    });
  return [
    for (final location in names)
      LocationGroup(
        location: location,
        items: grouped[location]!
          ..sort(
            (first, second) => second.createdAt.compareTo(first.createdAt),
          ),
        currentValue: grouped[location]!
            .where((item) => item.canAggregateInBaseCurrency)
            .fold<double>(0, (sum, item) => sum + item.currentTotal),
      ),
  ];
}
