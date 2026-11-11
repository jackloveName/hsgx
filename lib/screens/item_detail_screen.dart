import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_store.dart';
import '../components/info_row.dart';
import '../components/item_image_carousel.dart';
import '../components/item_relation_row.dart';
import '../components/item_tag_chip.dart';
import '../models.dart';
import '../storage/local_image_store.dart';
import '../widgets.dart';
import 'item_form_screen.dart';
import 'item_relations_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId, this.store});

  final String itemId;
  final AppStore? store;

  AppStore get _store => store ?? AppStore.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final item = _store.itemById(itemId);
        if (item == null) {
          return PageFrame(
            title: '一物一页',
            child: EmptyState(
              title: '未找到这件物品',
              description: '它可能已经被删除。',
              action: PrimaryButton(
                label: '返回',
                expanded: false,
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          );
        }
        final category = item.categoryInfo;
        final relatedItems = _store.items
            .where((candidate) => item.relatedItemIds.contains(candidate.id))
            .toList();
        final relatedCostItems = relatedItems
            .where(
              (candidate) =>
                  candidate.purchaseCurrency.toUpperCase() ==
                  item.purchaseCurrency.toUpperCase(),
            )
            .toList();
        final relatedUsageDaily = [
          item,
          ...relatedCostItems,
        ].fold<double>(0, (sum, entry) => sum + entry.usageAverageCost);
        final relatedOwnedDaily = [
          item,
          ...relatedCostItems,
        ].fold<double>(0, (sum, entry) => sum + entry.ownedDailyCost);
        return PageFrame(
          title: '一物一页',
          padding: const EdgeInsets.only(top: 8, bottom: 36),
          action: item.status == 'retired'
              ? null
              : IconButton(
                  tooltip: item.favorite ? '取消收藏' : '加入收藏',
                  onPressed: () => runStoreAction(
                    context,
                    () => _store.toggleFavorite(item.id),
                    successMessage: item.favorite ? '已移出珍爱' : '已放入珍爱',
                  ),
                  icon: Icon(
                    item.favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: item.favorite ? appPink : context.appMutedColor,
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemImageCarousel(item: item),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontFamily: 'Songti SC',
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              StatusPill(status: item.statusInfo),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            [
                              category.name,
                              if (item.subcategory.isNotEmpty) item.subcategory,
                              if (item.storageLocation.isNotEmpty)
                                item.storageLocation,
                            ].join(' · '),
                            style: TextStyle(
                              color: context.appMutedColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(height: 1, color: context.appBorderColor),
                          const SizedBox(height: 17),
                          Row(
                            children: [
                              Expanded(
                                child: MiniMetric(
                                  label: '购入总价',
                                  value:
                                      '${item.currencySymbol}${formatMoney(item.purchaseTotal)}',
                                ),
                              ),
                              Expanded(
                                child: MiniMetric(
                                  label: '当前总估值',
                                  value:
                                      '${item.currencySymbol}${formatMoney(item.currentTotal)}',
                                ),
                              ),
                              Expanded(
                                child: MiniMetric(
                                  label: item.usageMode == 'manual'
                                      ? '使用次数'
                                      : '使用天数',
                                  value:
                                      '${item.usageDays}${item.usageMode == "manual" ? " 次" : " 天"}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SectionHeading(title: '它与你的日常'),
                    SoftCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: MiniMetric(
                                  label: item.usageMode == 'manual'
                                      ? '使用次均'
                                      : '使用日均',
                                  value:
                                      '${item.currencySymbol}${formatMoney(item.usageAverageCost)}',
                                ),
                              ),
                              Expanded(
                                child: MiniMetric(
                                  label: '拥有日均',
                                  value:
                                      '${item.currencySymbol}${formatMoney(item.ownedDailyCost)}',
                                ),
                              ),
                              Expanded(
                                child: MiniMetric(
                                  label: '已拥有',
                                  value: '${item.ownedDays} 天',
                                ),
                              ),
                            ],
                          ),
                          if (item.effectiveTargetValue > 0) ...[
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Text(
                                  item.usageMode == 'manual'
                                      ? '目标次数进度'
                                      : '目标使用进度',
                                  style: TextStyle(
                                    color: context.appMutedColor,
                                    fontSize: 11,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${item.usageDays} / ${item.effectiveTargetValue} '
                                  '${item.targetUsageUnitLabel}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                minHeight: 7,
                                value:
                                    (item.usageDays / item.effectiveTargetValue)
                                        .clamp(0, 1),
                                backgroundColor: context.appSurfaceMutedColor,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SectionHeading(title: '最近的使用光景'),
                    _CostTrendCard(item: item),
                    if (item.hasRecoveryPlan) ...[
                      const SectionHeading(title: '惜物计划'),
                      SoftCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: '处理方式',
                              value: item.recoveryMethod,
                            ),
                            if (item.recoveryTargetPrice > 0)
                              _DetailRow(
                                label: '目标回血',
                                value:
                                    '${item.currencySymbol}${formatMoney(item.recoveryTargetPrice)}',
                              ),
                            if (item.recoveryDeadline.isNotEmpty)
                              _DetailRow(
                                label: '计划日期',
                                value: item.recoveryDeadline,
                              ),
                            if (item.recoveryPlatform.isNotEmpty)
                              _DetailRow(
                                label: '计划平台',
                                value: item.recoveryPlatform,
                              ),
                            if (item.recoveryContact.isNotEmpty)
                              _DetailRow(
                                label: '接收人',
                                value: item.recoveryContact,
                              ),
                            if (item.recoveryNote.isNotEmpty)
                              _DetailRow(
                                label: '计划备注',
                                value: item.recoveryNote,
                                multiline: true,
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SectionHeading(title: '拾物笺'),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          _DetailRow(label: '购入日期', value: item.purchaseDate),
                          _DetailRow(
                            label: '购入数量',
                            value: '${item.quantity.toInt()}',
                          ),
                          _DetailRow(
                            label: '购买渠道',
                            value: item.purchaseChannel.isEmpty
                                ? '--'
                                : item.purchaseChannel,
                          ),
                          _DetailRow(
                            label: '收纳位置',
                            value: item.storageLocation.isEmpty
                                ? '--'
                                : item.storageLocation,
                          ),
                          _DetailRow(
                            label: '保修/质期',
                            value: item.warrantyPeriod.isEmpty
                                ? '--'
                                : item.warrantyPeriod == '其他'
                                ? item.warrantyEndDate
                                : item.warrantyPeriod,
                          ),
                          if (item.netWeight.isNotEmpty)
                            _DetailRow(label: '净含量/克重', value: item.netWeight),
                          if (item.remainingNetWeight.isNotEmpty)
                            _DetailRow(
                              label: '剩余量',
                              value: item.remainingNetWeight,
                            ),
                          _DetailTagsRow(tags: item.tags),
                          _DetailRow(
                            label: '备注',
                            value: item.note.isEmpty ? '--' : item.note,
                            multiline: true,
                          ),
                        ],
                      ),
                    ),
                    if (item.status == 'idle' &&
                        item.idleReason.isNotEmpty) ...[
                      const SectionHeading(title: '暂歇记录'),
                      SoftCard(
                        child: _DetailRow(
                          label: '闲置原因',
                          value: item.idleReason,
                        ),
                      ),
                    ],
                    if (item.status == 'repairing') ...[
                      const SectionHeading(title: '养护记录'),
                      SoftCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: '维修平台',
                              value: item.repairPlatform.isEmpty
                                  ? '--'
                                  : item.repairPlatform,
                            ),
                            if (item.repairDays > 0)
                              _DetailRow(
                                label: '预计天数',
                                value: '${item.repairDays} 天',
                              ),
                            if (item.repairContactName.isNotEmpty)
                              _DetailRow(
                                label: '联系人',
                                value: item.repairContactName,
                              ),
                            if (item.repairContactPhone.isNotEmpty)
                              _DetailRow(
                                label: '联系电话',
                                value: item.repairContactPhone,
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SectionHeading(title: '相伴之物'),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    Theme.of(context).colorScheme.primary,
                                    Colors.white,
                                    0.88,
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  Icons.hub_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  relatedItems.isEmpty
                                      ? '还没有关联物品'
                                      : '已关联 ${relatedItems.length} 件物品',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: item.status == 'retired'
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ItemRelationsScreen(
                                            itemId: item.id,
                                          ),
                                        ),
                                      ),
                                child: Text('管理'),
                              ),
                            ],
                          ),
                          if (relatedItems.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: MiniMetric(
                                    label: '组合使用日均',
                                    value:
                                        '${item.currencySymbol}${formatMoney(relatedUsageDaily)}',
                                  ),
                                ),
                                Expanded(
                                  child: MiniMetric(
                                    label: '组合拥有日均',
                                    value:
                                        '${item.currencySymbol}${formatMoney(relatedOwnedDaily)}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < relatedItems.length;
                                  index++
                                ) ...[
                                  ItemRelationRow(
                                    key: Key(
                                      'detail-related-${relatedItems[index].id}',
                                    ),
                                    item: relatedItems[index],
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ItemDetailScreen(
                                          itemId: relatedItems[index].id,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index < relatedItems.length - 1)
                                    const ContentDivider(),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (item.status == 'processed' &&
                        item.disposalMethod.isNotEmpty) ...[
                      const SectionHeading(title: '离匣记录'),
                      SoftCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: '处理方式',
                              value: item.disposalMethod,
                            ),
                            if (item.disposalPlatform.isNotEmpty)
                              _DetailRow(
                                label: switch (item.disposalMethod) {
                                  '回收' => '回收平台',
                                  _ => '转卖平台',
                                },
                                value: item.disposalPlatform,
                              ),
                            if (item.disposalContact.isNotEmpty)
                              _DetailRow(
                                label: item.disposalMethod == '转赠'
                                    ? '接收人'
                                    : '转卖人',
                                value: item.disposalContact,
                              ),
                            if (item.disposalPlatform.isEmpty &&
                                item.disposalDetail.isNotEmpty)
                              _DetailRow(
                                label: item.disposalMethod == '转赠'
                                    ? '接收人'
                                    : '处理说明',
                                value: item.disposalDetail,
                              ),
                            if (item.isCashRecovery && item.disposalPrice > 0)
                              _DetailRow(
                                label: '净回血',
                                value:
                                    '${item.currencySymbol}${formatMoney(item.cashRecoveredAmount)}',
                              ),
                            if (item.isCashRecovery && item.disposalCost > 0)
                              _DetailRow(
                                label: '处理成本',
                                value:
                                    '${item.currencySymbol}${formatMoney(item.disposalCost)}',
                              ),
                            _DetailRow(
                              label: '处理日期',
                              value: item.processDate.isEmpty
                                  ? '--'
                                  : item.processDate,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SectionHeading(title: '它的生命轨迹'),
                    _StatusTimeline(item: item),
                    const SizedBox(height: 20),
                    if (item.status != 'retired' && item.status != 'processed')
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => _changeStatus(context, item),
                              style: FilledButton.styleFrom(
                                backgroundColor: Color.lerp(
                                  Theme.of(context).colorScheme.primary,
                                  Colors.white,
                                  0.88,
                                ),
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text('更改状态'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<InventoryItem?>(
                                    builder: (_) =>
                                        ItemFormScreen(initial: item),
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text('编辑'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('delete-item-button'),
                        onPressed: () => _delete(context, item),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: Theme.of(context).colorScheme.error,
                          backgroundColor: Color.alphaBlend(
                            Theme.of(context).colorScheme.error
                                .withValues(alpha: 0.08),
                            context.appSurfaceColor,
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error
                                .withValues(alpha: 0.24),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text('删除'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeStatus(BuildContext context, InventoryItem item) async {
    final selection = await showModalBottomSheet<_StatusSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StatusSheet(item: item),
    );
    if (selection == null) return;
    if (!context.mounted) return;
    if (selection.status == 'retired') {
      final confirmed = await confirmAction(
        context,
        title: '确认退役？',
        message: '退役后「${item.name}」将不能编辑或更改状态，只能删除。',
        confirmLabel: '确认退役',
        destructive: true,
      );
      if (!confirmed || !context.mounted) return;
    }
    await runStoreAction(
      context,
      () => _store.changeStatus(
        item.id,
        selection.status,
        idleReason: selection.idleReason,
        repairPlatform: selection.repairPlatform,
        repairDays: selection.repairDays,
        repairContactName: selection.repairContactName,
        repairContactPhone: selection.repairContactPhone,
        disposalMethod: selection.method,
        disposalDetail: selection.detail,
        disposalPlatform: selection.disposalPlatform,
        disposalContact: selection.disposalContact,
        disposalPrice: selection.price,
        disposalCost: selection.cost,
        processDate: selection.processDate,
      ),
      successMessage: '状态已更新为${statusById(selection.status).name}',
    );
  }

  Future<void> _delete(BuildContext context, InventoryItem item) async {
    final confirmed = await confirmAction(
      context,
      title: '删除物品',
      message: '确定删除“${item.name}”吗？此操作无法撤销。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    final deleted = await runStoreAction(
      context,
      () => _store.deleteItem(item.id),
      successMessage: '物品已删除',
    );
    if (deleted) {
      for (final imagePath in item.imagePaths) {
        try {
          await LocalImageStore.instance.delete(imagePath);
        } on Object {
          // The record is already removed; image cleanup should not block closing.
        }
      }
      if (context.mounted) Navigator.maybePop(context);
    }
  }
}

class _CostTrendCard extends StatelessWidget {
  const _CostTrendCard({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final points = List.generate(7, (index) {
      final date = DateTime(now.year, now.month, now.day - (6 - index));
      final ownedDays = item.ownedDaysAsOf(date);
      final usageDays = item.usageDaysAsOf(date);
      return (
        label: '${date.month}/${date.day}',
        owned: ownedDays <= 0 ? 0.0 : item.purchaseTotal / ownedDays,
        usage: item.usageMode == 'manual'
            ? item.usageAverageCost
            : usageDays <= 0
            ? 0.0
            : item.purchaseTotal / usageDays,
        target: item.targetAverageCost,
      );
    });
    final maxValue = points.fold<double>(
      1,
      (value, point) =>
          [value, point.owned, point.usage, point.target].reduce(math.max),
    );
    return SoftCard(
      child: Column(
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(
              painter: _CostTrendPainter(
                points: points,
                maxValue: maxValue,
                mutedColor: scheme.onSurfaceVariant,
                gridColor: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
              _LegendDot(
                color: const Color(0xFF129B88),
                label: item.usageMode == 'manual' ? '使用次均' : '使用日均',
              ),
              const _LegendDot(color: Color(0xFFE56B6F), label: '拥有日均'),
              if (item.targetAverageCost > 0)
                const _LegendDot(color: Color(0xFF5B7FA6), label: '目标日均'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: context.appMutedColor, fontSize: 9),
        ),
      ],
    );
  }
}

class _CostTrendPainter extends CustomPainter {
  _CostTrendPainter({
    required this.points,
    required this.maxValue,
    required this.mutedColor,
    required this.gridColor,
  });

  final List<({String label, double owned, double usage, double target})>
  points;
  final double maxValue;
  final Color mutedColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 24.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = top + chartHeight / 4 * index;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }
    void drawSeries(
      double Function(
        ({String label, double owned, double usage, double target}),
      )
      value,
      Color color,
    ) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (var index = 0; index < points.length; index++) {
        final x = left + chartWidth / (points.length - 1) * index;
        final y = top + chartHeight * (1 - value(points[index]) / maxValue);
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
      for (var index = 0; index < points.length; index++) {
        final x = left + chartWidth / (points.length - 1) * index;
        final y = top + chartHeight * (1 - value(points[index]) / maxValue);
        canvas.drawCircle(Offset(x, y), 2.7, Paint()..color = color);
      }
    }

    drawSeries((point) => point.owned, const Color(0xFFE56B6F));
    drawSeries((point) => point.usage, const Color(0xFF129B88));
    if (points.any((point) => point.target > 0)) {
      drawSeries((point) => point.target, const Color(0xFF5B7FA6));
    }
    for (var index = 0; index < points.length; index++) {
      final painter = TextPainter(
        text: TextSpan(
          text: points[index].label,
          style: TextStyle(color: mutedColor, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = left + chartWidth / (points.length - 1) * index;
      painter.paint(
        canvas,
        Offset(x - painter.width / 2, size.height - painter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CostTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.mutedColor != mutedColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return InfoRow(label: label, value: value, multiline: multiline);
  }
}

class _DetailTagsRow extends StatelessWidget {
  const _DetailTagsRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '标签',
                style: TextStyle(color: context.appMutedColor, fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: tags.isEmpty
                ? Text(
                    '--',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12),
                  )
                : Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var index = 0; index < tags.length; index++)
                        ItemTagChip(label: tags[index], index: index),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final history = item.statusHistory.reversed.toList();
    return SoftCard(
      child: Column(
        children: [
          for (var i = 0; i < history.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 20,
                    child: Stack(
                      children: [
                        if (i > 0)
                          Positioned(
                            top: 0,
                            left: 9.5,
                            height: 10,
                            child: Container(
                              width: 1,
                              color: context.appBorderColor,
                            ),
                          ),
                        if (i < history.length - 1)
                          Positioned(
                            top: 10,
                            bottom: 0,
                            left: 9.5,
                            child: Container(
                              width: 1,
                              color: context.appBorderColor,
                            ),
                          ),
                        Positioned(
                          key: Key('timeline-node-$i'),
                          top: 5,
                          left: 5,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusById(history[i].status).color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i == history.length - 1 ? 0 : 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            key: Key('timeline-status-$i'),
                            height: 20,
                            child: Row(
                              children: [
                                Text(
                                  statusById(history[i].status).name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  parseDate(history[i].at) == null
                                      ? '--'
                                      : formatDate(parseDate(history[i].at)!),
                                  style: TextStyle(
                                    color: context.appMutedColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ..._eventDetails(history[i]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _eventDetails(StatusEvent event) {
    if (event.status == 'repairing') {
      return [
        const SizedBox(height: 6),
        _TimelineDetailText('维修平台：${_valueOrDash(item.repairPlatform)}'),
        _TimelineDetailText(
          '预计维修时间：${item.repairDays > 0 ? '${item.repairDays}天' : '--'}',
        ),
        _TimelineDetailText('维修联系人：${_valueOrDash(item.repairContactName)}'),
        _TimelineDetailText('联系电话：${_valueOrDash(item.repairContactPhone)}'),
      ];
    }
    final note = event.status == 'inuse' && event.note.trim() == '物品初始状态'
        ? _initialInboxText(event)
        : event.note.trim();
    if (note.isEmpty) return const [];
    return [const SizedBox(height: 5), _TimelineDetailText(note)];
  }

  String _initialInboxText(StatusEvent event) {
    final date = parseDate(event.at) ?? item.purchaseDateTime;
    return '${date.year}年${date.month}月${date.day}号收入匣中';
  }

  String _valueOrDash(String value) {
    final clean = value.trim();
    return clean.isEmpty ? '--' : clean;
  }
}

class _TimelineDetailText extends StatelessWidget {
  const _TimelineDetailText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        text,
        style: TextStyle(
          color: context.appMutedColor,
          fontSize: 10,
          height: 1.45,
        ),
      ),
    );
  }
}

class _StatusReadOnlyValue extends StatelessWidget {
  const _StatusReadOnlyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurfaceMutedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: context.appMutedColor, fontSize: 11),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusSheet extends StatefulWidget {
  const _StatusSheet({required this.item});

  final InventoryItem item;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  late String _status = widget.item.status;
  late String _method = widget.item.recoveryMethod.isNotEmpty
      ? widget.item.recoveryMethod
      : widget.item.disposalMethod.isEmpty
      ? '转卖'
      : widget.item.disposalMethod;
  late String _repairPlatform = widget.item.repairPlatform;
  late String _disposalPlatform = widget.item.recoveryPlatform.isNotEmpty
      ? widget.item.recoveryPlatform
      : widget.item.disposalPlatform;
  late String _processDate = widget.item.processDate.isEmpty
      ? formatDate(DateTime.now())
      : widget.item.processDate;
  late final TextEditingController _idleReason;
  final _repairDays = TextEditingController();
  final _repairName = TextEditingController();
  final _repairPhone = TextEditingController();
  final _price = TextEditingController();
  final _detail = TextEditingController();

  static const _repairPlatforms = ['品牌官方', '官方授权维修', '第三方维修', '个人维修', '其他'];
  static const _salePlatforms = ['闲鱼', '转转', '得物', '线下二手', '朋友转卖', '其他'];
  static const _recyclePlatforms = ['爱回收', '转转回收', '品牌回收', '社区回收', '其他'];

  @override
  void initState() {
    super.initState();
    _idleReason = TextEditingController(text: widget.item.idleReason);
    _repairDays.text = widget.item.repairDays > 0
        ? '${widget.item.repairDays}'
        : '';
    _repairName.text = widget.item.repairContactName;
    _repairPhone.text = widget.item.repairContactPhone;
    final recoveryTarget = widget.item.recoveryTargetPrice;
    final displayPrice = widget.item.disposalPrice > 0
        ? widget.item.disposalPrice
        : recoveryTarget;
    _price.text = displayPrice > 0 ? formatMoney(displayPrice) : '';
    final existingDetail =
        widget.item.recoveryContact.isNotEmpty ||
            widget.item.recoveryPlatform.isNotEmpty
        ? [
            widget.item.recoveryContact,
            widget.item.recoveryPlatform,
          ].where((value) => value.isNotEmpty).join(' · ')
        : widget.item.disposalMethod == '转赠'
        ? widget.item.disposalContact
        : widget.item.disposalDetail;
    _detail.text = existingDetail;
  }

  @override
  void dispose() {
    _idleReason.dispose();
    _repairDays.dispose();
    _repairName.dispose();
    _repairPhone.dispose();
    _price.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _statusTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _statusHint,
                style: TextStyle(
                  color: context.appMutedColor,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in itemStatuses)
                    ChoiceChip(
                      selected: _status == status.id,
                      onSelected: (_) => setState(() => _status = status.id),
                      showCheckmark: false,
                      selectedColor: status.softColor,
                      backgroundColor: context.appSurfaceMutedColor,
                      side: BorderSide.none,
                      label: Text(
                        status.name,
                        style: TextStyle(
                          color: _status == status.id
                              ? status.color
                              : context.appMutedColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_status == 'idle')
                TextField(
                  controller: _idleReason,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: '闲置原因（选填）',
                    hintText: '例如：暂时用不上，先收纳一段时间',
                    counterText: '',
                  ),
                )
              else if (_status == 'repairing') ...[
                BottomSelectField<String>(
                  label: '维修平台',
                  value: _repairPlatform.isEmpty ? null : _repairPlatform,
                  hint: '请选择维修平台',
                  options: [
                    for (final platform in _repairPlatforms)
                      BottomSelectOption(value: platform, label: platform),
                  ],
                  onChanged: (value) =>
                      setState(() => _repairPlatform = value ?? ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _repairDays,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '预计维修天数',
                    suffixText: '天',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _repairName,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: '维修联系人（选填）',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _repairPhone,
                  maxLength: 20,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '联系电话（选填）',
                    counterText: '',
                  ),
                ),
              ] else if (_status == 'processed') ...[
                _StatusReadOnlyValue(
                  label: '购入价格',
                  value:
                      '${widget.item.currencySymbol}${formatMoney(widget.item.purchaseTotal)}',
                ),
                const SizedBox(height: 12),
                BottomSelectField<String>(
                  key: const Key('processing-method-field'),
                  label: '处理方式',
                  value: _method,
                  options: const [
                    BottomSelectOption(value: '转卖', label: '转卖'),
                    BottomSelectOption(value: '转赠', label: '转赠'),
                    BottomSelectOption(value: '回收', label: '回收'),
                    BottomSelectOption(value: '丢弃', label: '丢弃'),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _method = value;
                      _disposalPlatform = '';
                      _detail.clear();
                    });
                  },
                ),
                if (_method == '转卖' || _method == '回收') ...[
                  const SizedBox(height: 12),
                  BottomSelectField<String>(
                    key: const Key('processing-platform-field'),
                    label: _method == '回收' ? '回收平台' : '转卖平台',
                    value: _disposalPlatform.isEmpty ? null : _disposalPlatform,
                    hint: '请选择平台',
                    options: [
                      for (final platform
                          in _method == '回收'
                              ? _recyclePlatforms
                              : _salePlatforms)
                        BottomSelectOption(value: platform, label: platform),
                    ],
                    onChanged: (value) =>
                        setState(() => _disposalPlatform = value ?? ''),
                  ),
                ],
                if (_method == '转赠') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _detail,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: '接收人',
                      counterText: '',
                    ),
                  ),
                ],
                if (_method == '转卖' || _method == '回收') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '实际回血金额',
                      prefixText: '${widget.item.currencySymbol} ',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('process-date-picker'),
                    onPressed: _chooseProcessDate,
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size(0, 54),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      side: BorderSide(color: context.appBorderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 19,
                          color: context.appMutedColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '处理日期(购买日-至今)',
                                style: TextStyle(
                                  color: context.appMutedColor,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _processDate,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.appMutedColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              PrimaryButton(label: '确认更新', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  String get _statusTitle => switch (_status) {
    'idle' => '记录闲置',
    'repairing' => '记录维修',
    'processed' => '记录处理结果',
    'retired' => '确认物品退役',
    _ => '恢复使用',
  };

  String get _statusHint => switch (_status) {
    'idle' => '系统会暂停自动使用天数累计。',
    'repairing' => '维修期间不计入自动使用天数。',
    'processed' => '记录转卖、转赠或回收后的实际结果。',
    'retired' => '退役后不能继续建立新的组合关系。',
    _ => '物品将重新计入日常使用统计。',
  };

  Future<void> _chooseProcessDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final today = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: parseDate(_processDate) ?? today,
      firstDate: _processDateFirstDate,
      lastDate: today,
      title: '选择处理日期',
      confirmLabel: '确定处理日期',
    );
    if (picked != null) setState(() => _processDate = formatDate(picked));
  }

  DateTime get _processDateFirstDate {
    final today = DateUtils.dateOnly(DateTime.now());
    final purchaseDate = DateUtils.dateOnly(widget.item.purchaseDateTime);
    return purchaseDate.isAfter(today) ? today : purchaseDate;
  }

  void _submit() {
    if (_status == 'repairing' && _repairPlatform.isEmpty) {
      showAppSnack(context, '请选择维修平台');
      return;
    }
    if (_status == 'processed') {
      if ((_method == '转卖' || _method == '回收') && _disposalPlatform.isEmpty) {
        showAppSnack(context, _method == '回收' ? '请选择回收平台' : '请选择转卖平台');
        return;
      }
      if (_method == '转赠' && _detail.text.trim().isEmpty) {
        showAppSnack(context, '请输入接收人');
        return;
      }
      if ((_method == '转卖' || _method == '回收') &&
          (double.tryParse(_price.text.replaceAll(',', '')) ?? 0) <= 0) {
        showAppSnack(context, '请输入实际回血金额');
        return;
      }
    }
    Navigator.pop(
      context,
      _StatusSelection(
        status: _status,
        idleReason: _status == 'idle' ? _idleReason.text.trim() : '',
        repairPlatform: _status == 'repairing' ? _repairPlatform : '',
        repairDays: _status == 'repairing'
            ? int.tryParse(_repairDays.text) ?? 0
            : 0,
        repairContactName: _status == 'repairing'
            ? _repairName.text.trim()
            : '',
        repairContactPhone: _status == 'repairing'
            ? _repairPhone.text.trim()
            : '',
        method: _status == 'processed' ? _method : '',
        detail: _status == 'processed' ? _detail.text.trim() : '',
        disposalPlatform: _status == 'processed' ? _disposalPlatform : '',
        disposalContact:
            _status == 'processed' && (_method == '转卖' || _method == '转赠')
            ? _detail.text.trim()
            : '',
        price: _status == 'processed' && (_method == '转卖' || _method == '回收')
            ? double.tryParse(_price.text.replaceAll(',', '')) ?? 0
            : 0,
        cost: 0,
        processDate: _status == 'processed' ? _processDate : '',
      ),
    );
  }
}

class _StatusSelection {
  const _StatusSelection({
    required this.status,
    required this.idleReason,
    required this.repairPlatform,
    required this.repairDays,
    required this.repairContactName,
    required this.repairContactPhone,
    required this.method,
    required this.detail,
    required this.disposalPlatform,
    required this.disposalContact,
    required this.price,
    required this.cost,
    required this.processDate,
  });

  final String status;
  final String idleReason;
  final String repairPlatform;
  final int repairDays;
  final String repairContactName;
  final String repairContactPhone;
  final String method;
  final String detail;
  final String disposalPlatform;
  final String disposalContact;
  final double price;
  final double cost;
  final String processDate;
}
