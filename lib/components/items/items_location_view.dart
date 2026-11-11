import 'package:flutter/material.dart';

import '../../domain/items_browse.dart';
import '../../models.dart';
import '../item_summary_card.dart';

class ItemsLocationView extends StatelessWidget {
  const ItemsLocationView({
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
    final groups = groupItemsByLocation(items);
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = groups[index];
        return _LocationSection(
          group: group,
          onItemTap: onTap,
          onUsageChanged: onUsageChanged,
        );
      },
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.group,
    required this.onItemTap,
    required this.onUsageChanged,
  });

  final LocationGroup group;
  final ValueChanged<InventoryItem> onItemTap;
  final Future<void> Function(InventoryItem item, int delta) onUsageChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final unassigned = group.location == '未设置位置';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Color.lerp(primary, context.appSurfaceColor, 0.88),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  unassigned
                      ? Icons.layers_clear_outlined
                      : Icons.place_outlined,
                  color: unassigned ? context.appMutedColor : primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.location,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${group.items.length} 件',
                style: TextStyle(color: context.appMutedColor, fontSize: 9),
              ),
            ],
          ),
        ),
        for (var index = 0; index < group.items.length; index++) ...[
          ItemSummaryCard(
            key: ValueKey('location-item-card-${group.items[index].id}'),
            item: group.items[index],
            onTap: () => onItemTap(group.items[index]),
            onUsageChanged: (delta) =>
                onUsageChanged(group.items[index], delta),
            visualKey: Key('location-item-visual-${group.items[index].id}'),
            contentKey: Key('location-item-content-${group.items[index].id}'),
            usageKey: Key('location-manual-panel-${group.items[index].id}'),
            costKey: Key('location-usage-cost-${group.items[index].id}'),
            stepperKey: Key('location-manual-stepper-${group.items[index].id}'),
          ),
          if (index < group.items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
