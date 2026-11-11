import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../widgets.dart';
import 'storage_location_icons.dart';

class StorageSpaceCard extends StatelessWidget {
  const StorageSpaceCard({
    super.key,
    required this.location,
    required this.iconKey,
    required this.items,
    required this.onTap,
  });

  final String location;
  final String iconKey;
  final List<InventoryItem> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseItems = items.where(
      (item) => item.isActive && item.canAggregateInBaseCurrency,
    );
    final hasForeignCurrency = items.any(
      (item) => item.isActive && !item.canAggregateInBaseCurrency,
    );
    final value = baseItems.fold<double>(
      0,
      (sum, item) => sum + item.currentTotal,
    );
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = Color.lerp(primary, context.appSurfaceColor, 0.88)!;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: softPrimary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  storageLocationIcon(location, iconKey: iconKey),
                  color: primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.appMutedColor.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: _SpacePreview(items: items)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${items.length} 件',
                style: TextStyle(color: context.appMutedColor, fontSize: 9),
              ),
              const Spacer(),
              Text(
                hasForeignCurrency
                    ? '¥${formatMoney(value, compact: true)} + 外币'
                    : '¥${formatMoney(value, compact: true)}',
                style: TextStyle(
                  color: primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpacePreview extends StatelessWidget {
  const _SpacePreview({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: context.appSurfaceMutedColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: context.appBorderColor),
        ),
        child: Center(
          child: Icon(
            Icons.inventory_2_outlined,
            color: context.appMutedColor,
            size: 24,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbnailSize = math.min(
          constraints.maxHeight,
          (constraints.maxWidth - 10) / 3,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var index = 0; index < 3; index++)
              SizedBox.square(
                dimension: thumbnailSize,
                child: index < items.length
                    ? ItemVisual(
                        item: items[index],
                        size: thumbnailSize,
                        radius: 12,
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.appSurfaceMutedColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}
