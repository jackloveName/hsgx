import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/collection/collection_item_card.dart';
import '../models.dart';
import '../widgets.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, this.store});

  final AppStore? store;

  AppStore get _store => store ?? AppStore.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final favorites = _store.items.where((item) => item.favorite).toList()
          ..sort((a, b) => b.favoriteDateTime.compareTo(a.favoriteDateTime));
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
        return PageFrame.slivers(
          title: '珍爱之物',
          slivers: [
            SliverToBoxAdapter(
              child: GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '匣中珍爱',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '珍爱之物',
                      style: TextStyle(
                        fontFamily: 'Songti SC',
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
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
            ),
            const SliverToBoxAdapter(child: SectionHeading(title: '珍爱清单')),
            if (favorites.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  title: '珍爱清单还在等第一件物',
                  description: '打开任意物品详情，点击爱心即可放入珍爱。',
                  icon: Icons.favorite_border_rounded,
                ),
              )
            else
              SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 238,
                ),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final item = favorites[index];
                  return CollectionItemCard(
                    key: Key('collection-card-${item.id}'),
                    item: item,
                    onFavoriteTap: () => _removeFavorite(context, item),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _removeFavorite(BuildContext context, InventoryItem item) async {
    final confirmed = await confirmAction(
      context,
      title: '取消珍爱？',
      message: '「${item.name}」将从珍爱清单移除，物品本身仍会保留在匣中。',
      confirmLabel: '取消珍爱',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runStoreAction(
      context,
      () => _store.toggleFavorite(item.id),
      successMessage: '已取消珍爱',
    );
  }
}
