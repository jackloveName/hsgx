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
        final value = favorites.fold<double>(
          0,
          (sum, item) => sum + item.currentTotal,
        );
        final categories = favorites
            .map((item) => item.category)
            .toSet()
            .length;
        return PageFrame(
          title: '收藏馆',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                colors: const [Color(0xFF4EB6A2), Color(0xFF806CC2)],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MY COLLECTION',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '我的生活藏品',
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
                            label: '收藏物品',
                            value: '${favorites.length}',
                            dark: true,
                          ),
                        ),
                        Expanded(
                          child: MiniMetric(
                            label: '当前估值',
                            value: '¥${formatMoney(value, compact: true)}',
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
                title: '馆藏清单',
                trailing: Text(
                  '点击爱心收藏',
                  style: TextStyle(color: appMuted, fontSize: 10),
                ),
              ),
              if (favorites.isEmpty)
                const EmptyState(
                  title: '收藏馆还在等第一件藏品',
                  description: '打开任意物品详情，点击爱心即可放入收藏馆。',
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
                    childAspectRatio: 0.77,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final item = favorites[index];
                    return SoftCard(
                      padding: const EdgeInsets.all(10),
                      color: item.statusInfo.softColor,
                      borderColor: item.statusInfo.color.withValues(
                        alpha: 0.16,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ItemDetailScreen(itemId: item.id),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                  child: Center(
                                    child: ItemVisual(
                                      item: item,
                                      size: 110,
                                      radius: 16,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      'NO.${(index + 1).toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Color(0xFF6E6862),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: StatusPill(
                                    status: item.statusInfo,
                                    compact: true,
                                  ),
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
                              const Icon(
                                Icons.favorite_rounded,
                                size: 13,
                                color: appPink,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.categoryInfo.name,
                                  style: const TextStyle(
                                    color: appMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.currencySymbol}${formatMoney(item.currentTotal, compact: true)}',
                                style: const TextStyle(
                                  color: Color(0xFF2E7568),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
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
