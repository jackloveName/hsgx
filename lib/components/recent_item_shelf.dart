import 'package:flutter/material.dart';

import '../domain/item_display.dart';
import '../models.dart';
import '../widgets.dart';

class RecentItemShelf extends StatelessWidget {
  const RecentItemShelf({
    super.key,
    required this.items,
    required this.onTap,
    this.onLongPress,
  });

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onTap;
  final ValueChanged<InventoryItem>? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          SoftCard(
            padding: const EdgeInsets.all(12),
            radius: 22,
            onTap: () => onTap(items[index]),
            onLongPress: onLongPress == null
                ? null
                : () => onLongPress!(items[index]),
            child: Row(
              children: [
                ItemVisual(item: items[index], size: 66, radius: 17),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusPill(
                            status: items[index].statusInfo,
                            compact: true,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              items[index].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${items[index].categoryInfo.name} · '
                        '${items[index].storageLocation.isEmpty ? '待安放' : items[index].storageLocation}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: appMuted, fontSize: 9),
                      ),
                      if (recentUseText(items[index]) != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          recentUseText(items[index])!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB9B4AC),
                  size: 18,
                ),
              ],
            ),
          ),
          if (index < items.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}
