import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final favorites =
            AppStore.instance.items.where((item) => item.favorite).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final value = favorites
            .where((item) => item.isActive && item.canAggregateInBaseCurrency)
            .fold<double>(0, (sum, item) => sum + item.currentTotal);
        final hasForeignCurrency = favorites.any(
          (item) => item.isActive && !item.canAggregateInBaseCurrency,
        );
        final categories = favorites
            .map((item) => item.category)
            .toSet()
            .length;
        return PageFrame(
          title: '珍爱之物',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '匣中珍爱',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '珍爱之物',
                      style: TextStyle(
                        fontFamily: 'Songti SC',
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '喜欢的、常用的、舍不得忘记的，都值得被看见。',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: MiniMetric(
                            label: '珍爱物品',
                            value: '${favorites.length}',
                            dark: true,
                          ),
                        ),
                        Expanded(
                          child: MiniMetric(
                            label: '当前估值',
                            value: hasForeignCurrency
                                ? '¥${formatMoney(value, compact: true)} + 外币'
                                : '¥${formatMoney(value, compact: true)}',
                            dark: true,
                          ),
                        ),
                        Expanded(
                          child: MiniMetric(
                            label: '生活分类',
                            value: '$categories',
                            dark: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SectionHeading(
                title: '珍爱清单',
                trailing: Text(
                  '点击爱心放入珍爱',
                  style: TextStyle(color: appMuted, fontSize: 10),
                ),
              ),
              if (favorites.isEmpty)
                const EmptyState(
                  title: '珍爱清单还在等第一件物',
                  description: '打开任意物品详情，点击爱心即可放入珍爱。',
                  icon: Icons.favorite_border_rounded,
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 218,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final item = favorites[index];
                    return CollectionItemCard(
                      key: Key('collection-card-${item.id}'),
                      item: item,
                      index: index,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ItemDetailScreen(itemId: item.id),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class CollectionItemCard extends StatelessWidget {
  const CollectionItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onTap,
  });

  final InventoryItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      radius: 21,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                ItemPhoto(item: item, height: 143, radius: 0),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26342C).withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      'NO.${(index + 1).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: appPink,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: StatusPill(status: item.statusInfo, compact: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '${item.currencySymbol}${formatMoney(item.currentTotal, compact: true)}',
                style: TextStyle(
                  color: primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 12,
                color: appMuted.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  item.storageLocation.trim().isEmpty
                      ? '${item.categoryInfo.name} · 未设置位置'
                      : '${item.categoryInfo.name} · ${item.storageLocation}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appMuted, fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
