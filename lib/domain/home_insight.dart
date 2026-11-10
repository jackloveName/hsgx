import '../models.dart';

class HomeInsight {
  const HomeInsight({
    required this.title,
    required this.message,
    required this.action,
    required this.type,
    this.itemId,
  });

  final String title;
  final String message;
  final String action;
  final String type;
  final String? itemId;
}

HomeInsight buildHomeInsight(
  List<InventoryItem> items,
  List<WishEntry> wishlist, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final currentDay = DateTime(current.year, current.month, current.day);
  final active = items
      .where(
        (item) => const ['inuse', 'idle', 'repairing'].contains(item.status),
      )
      .toList();

  final warrantyItems =
      active
          .map((item) => (item: item, end: item.warrantyEnd))
          .where((entry) => entry.end != null)
          .map(
            (entry) => (
              item: entry.item,
              days: entry.end!
                  .difference(
                    DateTime(current.year, current.month, current.day),
                  )
                  .inDays,
            ),
          )
          .where((entry) => entry.days >= -30 && entry.days <= 30)
          .toList()
        ..sort((a, b) => a.days.abs().compareTo(b.days.abs()));
  if (warrantyItems.isNotEmpty) {
    final entry = warrantyItems.first;
    final expired = entry.days < 0;
    return HomeInsight(
      type: 'warranty',
      title: expired ? '有一件物品期限已经结束' : '有一件物品快到期限了',
      message: expired
          ? '${entry.item.name} 已过期 ${entry.days.abs()} 天，可以检查后续处理方式。'
          : '${entry.item.name} 还剩 ${entry.days} 天到期，适合安排一次检查。',
      action: 'detail',
      itemId: entry.item.id,
    );
  }

  final lowStock = active.where(_isLowStock).toList();
  if (lowStock.isNotEmpty) {
    final item = lowStock.first;
    return HomeInsight(
      type: 'stock',
      title: '有一件消耗品快用完了',
      message: '${item.name} 剩余 ${item.remainingNetWeight}，可以提前安排补充。',
      action: 'detail',
      itemId: item.id,
    );
  }

  final idle =
      active
          .where((item) => item.status == 'idle' && !item.hasRecoveryPlan)
          .toList()
        ..sort((a, b) => b.idleDays.compareTo(a.idleDays));
  if (idle.isNotEmpty && idle.first.idleDays >= 90) {
    final item = idle.first;
    return HomeInsight(
      type: 'idle',
      title: '给闲置物品一个决定',
      message: '${item.name} 已闲置 ${item.idleDays} 天，可以试用一次，也可以加入回血计划。',
      action: 'recovery',
      itemId: item.id,
    );
  }

  final coolingWish =
      wishlist.where((entry) => entry.status == 'cooling').toList()
        ..sort((a, b) => a.remainingDays.compareTo(b.remainingDays));
  if (coolingWish.isNotEmpty && coolingWish.first.remainingDays <= 3) {
    final entry = coolingWish.first;
    return HomeInsight(
      type: 'wishlist',
      title: '一个心愿快结束冷静期了',
      message: entry.remainingDays == 0
          ? '${entry.name} 的冷静期已经结束，现在可以做出决定。'
          : '${entry.name} 还有 ${entry.remainingDays} 天结束冷静期。',
      action: 'wishlist',
    );
  }

  final unused =
      active
          .where(
            (item) =>
                item.usageMode == 'manual' &&
                item.ownedDaysAsOf(current) >= 45 &&
                (item.lastUsedAt == null ||
                    currentDay
                            .difference(
                              DateTime(
                                item.lastUsedAt!.year,
                                item.lastUsedAt!.month,
                                item.lastUsedAt!.day,
                              ),
                            )
                            .inDays >=
                        60),
          )
          .toList()
        ..sort((a, b) => b.currentTotal.compareTo(a.currentTotal));
  if (unused.isNotEmpty) {
    final item = unused.first;
    return HomeInsight(
      type: 'ignored',
      title: '这件高价值物品很久没使用了',
      message: item.lastUsedAt == null
          ? '${item.name} 还没有使用记录，今天可以重新拿起，或评估是否继续保留。'
          : '${item.name} 已有 ${currentDay.difference(DateTime(item.lastUsedAt!.year, item.lastUsedAt!.month, item.lastUsedAt!.day)).inDays} 天没有使用。',
      action: 'detail',
      itemId: item.id,
    );
  }

  final frequentlyUsed = active.toList()
    ..sort((a, b) => b.usageDays.compareTo(a.usageDays));
  if (frequentlyUsed.isNotEmpty && frequentlyUsed.first.usageDays > 0) {
    final item = frequentlyUsed.first;
    return HomeInsight(
      type: 'positive',
      title: '你的生活正在被好好使用',
      message: item.usageMode == 'manual'
          ? '${item.name} 已记录使用 ${item.usageDays} 次，是收藏匣里的高频伙伴。'
          : '${item.name} 已累计使用 ${item.usageDays} 天，是收藏匣里的高频伙伴。',
      action: 'detail',
      itemId: item.id,
    );
  }

  return const HomeInsight(
    type: 'empty',
    title: '从第一件美好开始',
    message: '登记一件正在使用的物品，让生活资产逐渐清晰。',
    action: 'add',
  );
}

bool _isLowStock(InventoryItem item) {
  if (item.status != 'inuse') return false;
  final initial = double.tryParse(
    item.netWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
  );
  final remaining = double.tryParse(
    item.remainingNetWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
  );
  if (initial == null || remaining == null || initial <= 0) return false;
  return remaining / initial <= 0.2;
}
