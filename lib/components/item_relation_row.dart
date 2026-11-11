import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';
import 'item_name_text.dart';
import 'item_summary_card.dart';

class ItemRelationRow extends StatelessWidget {
  const ItemRelationRow({
    super.key,
    required this.item,
    this.onTap,
    this.onRemove,
  });

  final InventoryItem item;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          StatusPill(status: item.statusInfo, compact: true),
          const SizedBox(width: 8),
          Expanded(
            child: ItemNameText(
              name: item.name,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: onRemove == null ? 74 : 68,
            child: ItemUsageCost(item: item, alignment: Alignment.centerRight),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: '移除关联',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: context.appMutedColor,
              ),
            ),
        ],
      ),
    );
    if (onTap == null) {
      return Material(color: Colors.transparent, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}
