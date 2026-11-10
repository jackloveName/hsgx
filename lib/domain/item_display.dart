import '../models.dart';

String? recentUseText(InventoryItem item, {DateTime? now}) {
  final lastUsed = item.lastUsedAtAsOf(now ?? DateTime.now());
  return lastUsed == null ? null : '最近使用：${formatDate(lastUsed)}';
}
