import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/filter_pill_bar.dart';
import '../components/item_list_card.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';

class InsightItemsScreen extends StatefulWidget {
  const InsightItemsScreen({
    super.key,
    required this.type,
    this.category = '',
    this.subcategory = '',
    this.subcategoryLabel = '',
    this.initialRange = '',
  });

  final String type;
  final String category;
  final String subcategory;
  final String subcategoryLabel;
  final String initialRange;

  @override
  State<InsightItemsScreen> createState() => _InsightItemsScreenState();
}

class _InsightItemsScreenState extends State<InsightItemsScreen> {
  static const _ranges = [
    (id: 'under-month', label: '少于1个月', min: 0, max: 29),
    (id: 'one-six-months', label: '1~6个月', min: 30, max: 179),
    (id: 'six-one-year', label: '6~1年', min: 180, max: 364),
    (id: 'one-three-years', label: '1~3年', min: 365, max: 1094),
    (id: 'over-three-years', label: '3年以上', min: 1095, max: 999999),
  ];

  late String _range;

  @override
  void initState() {
    super.initState();
    _range = _ranges.any((range) => range.id == widget.initialRange)
        ? widget.initialRange
        : _ranges.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final items = _filteredItems(AppStore.instance.items);
        return PageFrame(
          title: _title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '共 ${items.length} 件物品',
                style: const TextStyle(color: appMuted, fontSize: 11),
              ),
              if (widget.type == 'holding') ...[
                const SizedBox(height: 12),
                FilterPillBar(
                  options: [
                    for (final range in _ranges)
                      FilterPillOption(
                        value: range.id,
                        label: range.label,
                        color: Theme.of(context).colorScheme.primary,
                        backgroundColor: Color.lerp(
                          Theme.of(context).colorScheme.primary,
                          Colors.white,
                          0.86,
                        )!,
                      ),
                  ],
                  value: _range,
                  onChanged: (value) => setState(() => _range = value),
                  padding: EdgeInsets.zero,
                ),
              ],
              const SizedBox(height: 14),
              if (items.isEmpty)
                EmptyState(
                  title: widget.type == 'warning' ? '暂无重复购买物品' : '暂无数据',
                  description: '当前筛选条件下没有物品。',
                  icon: Icons.filter_alt_off_outlined,
                )
              else
                for (final item in items) ...[
                  ItemListCard(
                    item: item,
                    compactValue: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ItemDetailScreen(itemId: item.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  String get _title => switch (widget.type) {
    'warning' =>
      widget.subcategoryLabel.isEmpty
          ? categoryById(widget.category).name
          : '${categoryById(widget.category).name} · ${widget.subcategoryLabel}',
    'holding' => '全部物品',
    'expiring' => '即将到期',
    'expired' => '期限已过',
    'low-stock' => '库存不足',
    _ => '闲置资产',
  };

  List<InventoryItem> _filteredItems(List<InventoryItem> source) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return switch (widget.type) {
      'warning' =>
        source
            .where(
              (item) =>
                  item.category == widget.category &&
                  item.subcategory == widget.subcategory,
            )
            .toList(),
      'holding' => source.where((item) {
        final range = _ranges.firstWhere((entry) => entry.id == _range);
        return item.ownedDays >= range.min && item.ownedDays <= range.max;
      }).toList(),
      'expiring' => source.where((item) {
        if (!const ['inuse', 'idle', 'repairing'].contains(item.status)) {
          return false;
        }
        final end = item.warrantyEnd;
        if (end == null) return false;
        final days = end.difference(startOfToday).inDays;
        return days >= 0 && days <= 30;
      }).toList(),
      'expired' => source.where((item) {
        if (!const ['inuse', 'idle', 'repairing'].contains(item.status)) {
          return false;
        }
        final end = item.warrantyEnd;
        return end != null && end.isBefore(startOfToday);
      }).toList(),
      'low-stock' => source.where((item) {
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
      }).toList(),
      _ => source.where((item) => item.status == 'idle').toList(),
    };
  }
}
