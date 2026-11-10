import 'package:flutter/material.dart';

import '../../models.dart';
import '../../widgets.dart';

class StorageUnassignedInbox extends StatelessWidget {
  const StorageUnassignedInbox({
    super.key,
    required this.items,
    required this.totalCount,
    required this.onTap,
  });

  final List<InventoryItem> items;
  final int totalCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SoftCard(
      onTap: onTap,
      color: Color.lerp(Colors.white, primary, 0.07)!,
      borderColor: primary.withValues(alpha: 0.24),
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.move_to_inbox_outlined, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalCount 件物品暂未归处',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  items.take(3).map((item) => item.name).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appMuted, fontSize: 9),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: primary, size: 20),
        ],
      ),
    );
  }
}
