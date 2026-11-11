import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';
import 'item_name_text.dart';

class ItemListCard extends StatelessWidget {
  const ItemListCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.compactValue = true,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          ItemVisual(item: item, size: 60, radius: 16),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: ItemNameText(
                        name: item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.favorite) ...[
                      const SizedBox(width: 5),
                      Icon(Icons.favorite_rounded, size: 12, color: appPink),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.categoryInfo.name} · '
                  '${item.storageLocation.isEmpty ? '未设置位置' : item.storageLocation}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appMutedColor, fontSize: 11),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    StatusPill(status: item.statusInfo, compact: true),
                    const Spacer(),
                    Text(
                      '${item.currencySymbol}${formatMoney(item.currentTotal, compact: compactValue)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
