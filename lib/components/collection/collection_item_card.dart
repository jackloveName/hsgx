import 'package:flutter/material.dart';

import '../../models.dart';
import '../../widgets.dart';
import '../item_name_text.dart';

class CollectionItemCard extends StatelessWidget {
  const CollectionItemCard({
    super.key,
    required this.item,
    required this.onFavoriteTap,
  });

  final InventoryItem item;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SoftCard(
      padding: const EdgeInsets.all(8),
      radius: 21,
      color: context.appSurfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                ItemPhoto(item: item, height: 143, radius: 0),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Tooltip(
                    message: '取消珍爱',
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: Key('collection-favorite-toggle-${item.id}'),
                        onTap: onFavoriteTap,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 15,
                            color: appPink,
                          ),
                        ),
                      ),
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
                child: ItemNameText(
                  name: item.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
                color: context.appMutedColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  item.storageLocation.trim().isEmpty
                      ? '${item.categoryInfo.name} · 未设置位置'
                      : '${item.categoryInfo.name} · ${item.storageLocation}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appMutedColor, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '珍藏于 ${_favoriteDateLabel(item.favoriteDateTime)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFB06E83),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _favoriteDateLabel(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${date.year}.${twoDigits(date.month)}.${twoDigits(date.day)}';
}
