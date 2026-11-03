import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets.dart';
import 'insight_items_screen.dart';
import 'recovery_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  static const _holdingRanges = [
    (id: 'under-month', label: '少于 1 个月', min: 0, max: 29),
    (id: 'one-six-months', label: '1~6 个月', min: 30, max: 179),
    (id: 'six-one-year', label: '6 个月~1 年', min: 180, max: 364),
    (id: 'one-three-years', label: '1~3 年', min: 365, max: 1094),
    (id: 'over-three-years', label: '3 年以上', min: 1095, max: 999999),
  ];

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final items = store.items;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final active = items
        .where(
          (item) => const ['inuse', 'idle', 'repairing'].contains(item.status),
        )
        .toList();
    final expiring = active.where((item) {
      final end = item.warrantyEnd;
      if (end == null) return false;
      final days = end.difference(today).inDays;
      return days >= 0 && days <= 30;
    }).length;
    final expired = active.where((item) {
      final end = item.warrantyEnd;
      return end != null && end.isBefore(today);
    }).length;
    final lowStock = items.where((item) {
      final initial = double.tryParse(
        item.netWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
      );
      final remaining = double.tryParse(
        item.remainingNetWeight.replaceAll(RegExp(r'[^0-9.]'), ''),
      );
      return initial != null &&
          remaining != null &&
          initial > 0 &&
          remaining / initial <= 0.2;
    }).length;
    final longest = items.isEmpty
        ? null
        : (items.toList()..sort((a, b) => b.ownedDays.compareTo(a.ownedDays)))
              .first;
    final distributions =
        itemCategories
            .map((category) {
              final value = items
                  .where((item) => item.category == category.id)
                  .fold<double>(0, (sum, item) => sum + item.currentTotal);
              return (category: category, value: value);
            })
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final distTotal = distributions.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );
    final costs =
        itemCategories
            .map((category) {
              final value = items
                  .where((item) => item.category == category.id)
                  .fold<double>(0, (sum, item) => sum + item.ownedDailyCost);
              return (category: category, value: value);
            })
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final warningGroups = <String, List<InventoryItem>>{};
    for (final item in items) {
      if (item.subcategory.trim().isEmpty) continue;
      warningGroups
          .putIfAbsent(
            '${item.category}::${item.subcategory}',
            () => <InventoryItem>[],
          )
          .add(item);
    }
    final warnings =
        warningGroups.values.where((group) => group.length >= 3).toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    final idleItems = items.where((item) => item.status == 'idle').toList();
    final idleValue = idleItems.fold<double>(
      0,
      (sum, item) => sum + item.currentTotal,
    );
    return AppBackdrop(
      child: SafeArea(
        bottom: false,
        child: ContentPane(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 116),
            children: [
              GradientCard(
                colors: const [Color(0xFFE4B15C), Color(0xFFE28789)],
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '持有与期限',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _InsightCount(
                            value: '$expiring',
                            label: '即将到期',
                            icon: Icons.schedule_rounded,
                            onTap: () => _openList(context, 'expiring'),
                          ),
                        ),
                        Expanded(
                          child: _InsightCount(
                            value: '$expired',
                            label: '已经过期',
                            icon: Icons.history_toggle_off_rounded,
                            onTap: () => _openList(context, 'expired'),
                          ),
                        ),
                        Expanded(
                          child: _InsightCount(
                            value: '$lowStock',
                            label: '库存预警',
                            icon: Icons.inventory_2_outlined,
                            onTap: () => _openList(context, 'low-stock'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: MiniMetric(
                            label: '最长持有',
                            value: '${longest?.ownedDays ?? 0} 天',
                            dark: true,
                          ),
                        ),
                        Expanded(
                          child: MiniMetric(
                            label: '平均持有',
                            value: items.isEmpty
                                ? '0 天'
                                : '${(items.fold<int>(0, (sum, item) => sum + item.ownedDays) / items.length).round()} 天',
                            dark: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SectionHeading(title: '持有区间'),
              SoftCard(
                child: Column(
                  children: [
                    for (final range in _holdingRanges) ...[
                      _HoldingRangeRow(
                        label: range.label,
                        count: items
                            .where(
                              (item) =>
                                  item.ownedDays >= range.min &&
                                  item.ownedDays <= range.max,
                            )
                            .length,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => InsightItemsScreen(
                              type: 'holding',
                              initialRange: range.id,
                            ),
                          ),
                        ),
                      ),
                      if (range != _holdingRanges.last)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const SectionHeading(title: '资产分布'),
              SoftCard(
                child: distributions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            '添加物品后会生成资产分布',
                            style: TextStyle(color: appMuted, fontSize: 12),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          _DistributionBar(distributions: distributions),
                          const SizedBox(height: 18),
                          for (final entry in distributions.take(5)) ...[
                            _CategoryValueRow(
                              category: entry.category,
                              value: entry.value,
                              percent: distTotal == 0
                                  ? 0
                                  : entry.value / distTotal,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
              ),
              const SectionHeading(title: '品类日均成本'),
              SoftCard(
                child: costs.isEmpty
                    ? const Text(
                        '暂无数据',
                        style: TextStyle(color: appMuted, fontSize: 12),
                      )
                    : Column(
                        children: [
                          for (
                            var i = 0;
                            i < math.min(5, costs.length);
                            i++
                          ) ...[
                            _CostRow(
                              rank: i + 1,
                              category: costs[i].category,
                              value: costs[i].value,
                              max: costs.first.value,
                            ),
                            if (i < math.min(5, costs.length) - 1)
                              const SizedBox(height: 14),
                          ],
                        ],
                      ),
              ),
              if (warnings.isNotEmpty) ...[
                const SectionHeading(title: '重复购买提醒'),
                for (final group in warnings) ...[
                  _WarningCard(
                    group: group,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => InsightItemsScreen(
                          type: 'warning',
                          category: group.first.category,
                          subcategory: group.first.subcategory,
                          subcategoryLabel: group.first.subcategory,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              const SectionHeading(title: '闲置回血'),
              SoftCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RecoveryScreen(),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE7CE), Color(0xFFFFD9E5)],
                        ),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.recycling_rounded,
                        color: Color(0xFFC48745),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${idleItems.length} 件闲置物品',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '当前估值 ¥${formatMoney(idleValue)} · 预计可回收 ¥${formatMoney(idleValue * 0.7)}',
                            style: const TextStyle(
                              color: appMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFABA59D),
                    ),
                  ],
                ),
              ),
              const SectionHeading(title: '近 6 个月购入'),
              _MonthlyBars(items: items),
            ],
          ),
        ),
      ),
    );
  }

  void _openList(BuildContext context, String type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => InsightItemsScreen(type: type)),
    );
  }
}

class _InsightCount extends StatelessWidget {
  const _InsightCount({
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 17),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldingRangeRow extends StatelessWidget {
  const _HoldingRangeRow({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 12)),
              ),
              Text(
                '$count 件',
                style: const TextStyle(
                  color: appMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: appMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.distributions});

  final List<({ItemCategory category, double value})> distributions;

  @override
  Widget build(BuildContext context) {
    final total = distributions.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            for (final entry in distributions)
              Expanded(
                flex: math.max(1, (entry.value / total * 1000).round()),
                child: ColoredBox(color: entry.category.color),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryValueRow extends StatelessWidget {
  const _CategoryValueRow({
    required this.category,
    required this.value,
    required this.percent,
  });

  final ItemCategory category;
  final double value;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            category.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${(percent * 100).round()}%',
          style: const TextStyle(color: appMuted, fontSize: 10),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: Text(
            '¥${formatMoney(value, compact: true)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.rank,
    required this.category,
    required this.value,
    required this.max,
  });

  final int rank;
  final ItemCategory category;
  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: rank <= 3 ? category.softColor : const Color(0xFFF4F1ED),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              color: rank <= 3 ? category.color : appMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '¥${formatMoney(value)} / 天',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: max == 0 ? 0 : value / max,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFF1EEE9),
                  color: category.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.group, required this.onTap});

  final List<InventoryItem> group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final first = group.first;
    final value = group.fold<double>(
      0,
      (sum, item) => sum + item.purchaseTotal,
    );
    return SoftCard(
      onTap: onTap,
      color: const Color(0xFFFFFBF2),
      borderColor: const Color(0xFFF0DFBC),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF3DF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.content_copy_rounded,
              color: first.categoryInfo.color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${first.categoryInfo.name} · ${first.subcategory}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '已记录 ${group.length} 件，累计购入 '
                  '${first.currencySymbol}${formatMoney(value)}',
                  style: const TextStyle(color: appMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: appMuted),
        ],
      ),
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({required this.items});

  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index);
      final value = items
          .where((item) {
            final date = parseDate(item.purchaseDate);
            return date != null &&
                date.year == month.year &&
                date.month == month.month;
          })
          .fold<double>(0, (sum, item) => sum + item.purchaseTotal);
      return (month: month, value: value);
    });
    final maxValue = months.fold<double>(
      1,
      (max, entry) => math.max(max, entry.value),
    );
    return SoftCard(
      child: SizedBox(
        height: 170,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final entry in months)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      entry.value == 0
                          ? ''
                          : '¥${formatMoney(entry.value, compact: true)}',
                      style: const TextStyle(color: appMuted, fontSize: 8),
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      height: math.max(5, entry.value / maxValue * 100),
                      width: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: entry.value > 0
                              ? [appPrimary.withValues(alpha: 0.65), appPrimary]
                              : [
                                  const Color(0xFFF0ECE6),
                                  const Color(0xFFF0ECE6),
                                ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '${entry.month.month}月',
                      style: const TextStyle(color: appMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
