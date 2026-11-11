import 'package:flutter/material.dart';

import '../../models.dart';
import '../../widgets.dart';
import '../item_name_text.dart';

class StorageItemCard extends StatelessWidget {
  const StorageItemCard({super.key, required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showStatus = !const {
      'repairing',
      'processed',
      'retired',
    }.contains(item.status);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ItemPhoto(item: item, height: 126, radius: 15),
              if (showStatus)
                Positioned(
                  left: 7,
                  top: 7,
                  child: StatusPill(status: item.statusInfo, compact: true),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ItemNameText(
            name: item.name,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.categoryInfo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appMutedColor, fontSize: 9),
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
