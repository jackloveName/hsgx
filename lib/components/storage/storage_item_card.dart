import 'package:flutter/material.dart';

import '../../models.dart';
import '../../widgets.dart';

class StorageItemCard extends StatelessWidget {
  const StorageItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMove,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      onLongPress: onMove,
      padding: const EdgeInsets.all(8),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ItemPhoto(item: item, height: 126, radius: 15),
              Positioned(
                left: 7,
                top: 7,
                child: StatusPill(status: item.statusInfo, compact: true),
              ),
              Positioned(
                right: 7,
                bottom: 7,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onMove,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(Icons.drive_file_move_outline, size: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.categoryInfo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appMuted, fontSize: 9),
                ),
              ),
              Text(
                '${item.currencySymbol}${formatMoney(item.currentTotal, compact: true)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 9,
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
