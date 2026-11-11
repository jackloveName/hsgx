import 'package:flutter/material.dart';

import '../../models.dart';
import '../item_summary_card.dart';

class ItemsLedgerView extends StatelessWidget {
  const ItemsLedgerView({
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
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return ItemSummaryCard(
          item: item,
          onTap: () => onTap(item),
          onUsageChanged: (delta) => onUsageChanged(item, delta),
          costKey: Key('ledger-usage-cost-${item.id}'),
          stepperKey: Key('ledger-manual-stepper-${item.id}'),
        );
      },
    );
  }
}
