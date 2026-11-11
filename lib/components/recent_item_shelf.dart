import 'package:flutter/material.dart';

import 'item_summary_card.dart';
import '../models.dart';

class RecentItemShelf extends StatelessWidget {
  const RecentItemShelf({super.key, required this.items, required this.onTap});

  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          ItemSummaryCard(
            item: items[index],
            onTap: () => onTap(items[index]),
            showUsageAction: false,
            showUsageQuantity: false,
            showChevron: true,
          ),
          if (index < items.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}
