import 'package:flutter/material.dart';

import '../domain/item_display.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_name_text.dart';

class ItemSummaryCard extends StatelessWidget {
  const ItemSummaryCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    this.onUsageChanged,
    this.showUsageAction = true,
    this.showUsageQuantity = true,
    this.showChevron = false,
    this.costKey,
    this.stepperKey,
    this.visualKey,
    this.contentKey,
    this.usageKey,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Future<void> Function(int delta)? onUsageChanged;
  final bool showUsageAction;
  final bool showUsageQuantity;
  final bool showChevron;
  final Key? costKey;
  final Key? stepperKey;
  final Key? visualKey;
  final Key? contentKey;
  final Key? usageKey;

  @override
  Widget build(BuildContext context) {
    final statusDuration = itemStatusDurationText(item);
    return SoftCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(12),
      radius: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemVisual(key: visualKey, item: item, size: 66, radius: 17),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              key: contentKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(status: item.statusInfo, compact: true),
                    const SizedBox(width: 7),
                    Expanded(
                      child: ItemNameText(
                        name: item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  itemMetadataText(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appMutedColor, fontSize: 9),
                ),
                if (statusDuration != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    statusDuration,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appMutedColor, fontSize: 9),
                  ),
                ],
                if (showUsageQuantity &&
                    item.usageMode != 'manual' &&
                    item.status != 'retired') ...[
                  const SizedBox(height: 3),
                  Text(
                    itemUsageQuantityText(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appMutedColor, fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
          if (showUsageAction) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: item.canRecordManualUsage
                  ? ItemManualUsageControl(
                      key: usageKey,
                      item: item,
                      alignment: Alignment.centerRight,
                      onUsageChanged: onUsageChanged,
                      costKey: costKey,
                      stepperKey: stepperKey,
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: ItemUsageCost(
                        key: costKey,
                        item: item,
                        alignment: Alignment.centerRight,
                      ),
                    ),
            ),
          ],
          if (showChevron) ...[
            const SizedBox(width: 5),
            Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB9B4AC),
              size: 18,
            ),
          ],
        ],
      ),
    );
  }
}

class ItemCategoryTag extends StatelessWidget {
  const ItemCategoryTag({super.key, required this.category});

  final ItemCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: category.softColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: category.color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ItemUsageCost extends StatelessWidget {
  const ItemUsageCost({
    super.key,
    required this.item,
    this.alignment = Alignment.centerLeft,
  });

  final InventoryItem item;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final amount =
        '${item.currencySymbol}${formatMoney(item.usageAverageCost)}';
    final unit = item.usageMode == 'manual' ? '次' : '天';
    final text = '$amount/$unit';
    return Align(
      alignment: alignment,
      child: Semantics(
        label: text,
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: amount,
                  style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: '/$unit',
                  style: TextStyle(
                    color: context.appMutedColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class ItemManualUsageControl extends StatelessWidget {
  const ItemManualUsageControl({
    super.key,
    required this.item,
    required this.onUsageChanged,
    this.alignment = Alignment.centerLeft,
    this.costKey,
    this.stepperKey,
  });

  final InventoryItem item;
  final Future<void> Function(int delta)? onUsageChanged;
  final Alignment alignment;
  final Key? costKey;
  final Key? stepperKey;

  @override
  Widget build(BuildContext context) {
    final callback = onUsageChanged;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment == Alignment.centerRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        ItemUsageCost(key: costKey, item: item, alignment: alignment),
        const SizedBox(height: 4),
        ItemUsageStepper(
          key: stepperKey,
          itemId: item.id,
          count: item.manualUsageCount,
          onDecrement: callback == null || item.manualUsageCount <= 0
              ? null
              : () => runStoreAction(context, () => callback(-1)),
          onIncrement: callback == null
              ? null
              : () => runStoreAction(
                  context,
                  () => callback(1),
                  successMessage: '已记录一次使用',
                ),
        ),
      ],
    );
  }
}

class ItemUsageStepper extends StatelessWidget {
  static const double width = 84;

  const ItemUsageStepper({
    super.key,
    required this.itemId,
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
    this.size = width,
    this.buttonWidth = 30,
  });

  final String itemId;
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final double size;
  final double buttonWidth;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      child: Semantics(
        container: true,
        label: '使用次数',
        value: '$count',
        child: Container(
          height: 30,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              _UsageStepButton(
                key: Key('manual-usage-decrement-$itemId'),
                icon: Icons.remove_rounded,
                label: '减少一次使用',
                onTap: onDecrement,
                width: buttonWidth,
              ),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _UsageStepButton(
                key: Key('manual-usage-increment-$itemId'),
                icon: Icons.add_rounded,
                label: '增加一次使用',
                onTap: onIncrement,
                width: buttonWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageStepButton extends StatelessWidget {
  const _UsageStepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.width,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: width,
            height: 28,
            child: Icon(
              icon,
              size: 15,
              color: onTap == null
                  ? context.appMutedColor.withValues(alpha: 0.35)
                  : primary,
            ),
          ),
        ),
      ),
    );
  }
}

String itemMetadataText(InventoryItem item) {
  final location = item.storageLocation.trim().isEmpty
      ? '待安放'
      : item.storageLocation.trim();
  return '${item.categoryInfo.name} · $location';
}

String itemUsageQuantityText(InventoryItem item) {
  return item.usageMode == 'manual'
      ? '已记录 ${item.manualUsageCount} 次'
      : '已使用 ${item.usageDays} 天';
}
