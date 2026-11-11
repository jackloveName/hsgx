import 'package:flutter/material.dart';

import '../../domain/item_display.dart';
import '../../models.dart';
import '../../widgets.dart';
import '../item_name_text.dart';
import '../item_summary_card.dart';

class ItemsGalleryView extends StatelessWidget {
  const ItemsGalleryView({
    super.key,
    required this.items,
    required this.controller,
    required this.onTap,
    required this.onUsageChanged,
  });

  final List<InventoryItem> items;
  final ScrollController controller;
  final ValueChanged<InventoryItem> onTap;
  final Future<void> Function(InventoryItem item, int delta) onUsageChanged;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 258,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = items[index];
              return _GalleryItemCard(
                item: item,
                onTap: () => onTap(item),
                onUsageChanged: (delta) => onUsageChanged(item, delta),
              );
            }, childCount: items.length),
          ),
        ),
      ],
    );
  }
}

class _GalleryItemCard extends StatelessWidget {
  const _GalleryItemCard({
    required this.item,
    required this.onTap,
    required this.onUsageChanged,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final Future<void> Function(int delta) onUsageChanged;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      radius: 21,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ItemPhoto(
                        item: item,
                        height: constraints.maxHeight,
                        radius: 0,
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: StatusPill(
                          status: item.statusInfo,
                          compact: true,
                        ),
                      ),
                      if (item.favorite)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: appPink,
                              size: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              ItemCategoryTag(category: item.categoryInfo),
              const SizedBox(width: 6),
              Expanded(
                child: ItemNameText(
                  name: item.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (item.canRecordManualUsage) ...[
            ItemUsageCost(
              key: Key('gallery-usage-cost-${item.id}'),
              item: item,
              alignment: Alignment.centerRight,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: double.infinity,
                child: ItemUsageStepper(
                  key: Key('gallery-manual-stepper-${item.id}'),
                  itemId: item.id,
                  count: item.manualUsageCount,
                  size: double.infinity,
                  onDecrement: item.manualUsageCount <= 0
                      ? null
                      : () => runStoreAction(context, () => onUsageChanged(-1)),
                  onIncrement: () => runStoreAction(
                    context,
                    () => onUsageChanged(1),
                    successMessage: '已记录一次使用',
                  ),
                ),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    itemBrowseContext(item, includeUsageCost: false),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appMutedColor,
                      fontSize: 9,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ItemUsageCost(
                    item: item,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
