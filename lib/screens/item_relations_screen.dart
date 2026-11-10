import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';

class ItemRelationsScreen extends StatefulWidget {
  const ItemRelationsScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<ItemRelationsScreen> createState() => _ItemRelationsScreenState();
}

class _ItemRelationsScreenState extends State<ItemRelationsScreen> {
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected =
        AppStore.instance.itemById(widget.itemId)?.relatedItemIds.toSet() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final store = AppStore.instance;
        final item = store.itemById(widget.itemId);
        if (item == null) {
          return PageFrame(
            title: '关联物品',
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
        final selectedItems = store.items
            .where((entry) => _selected.contains(entry.id))
            .toList();
        final selectedCostItems = selectedItems
            .where(
              (entry) =>
                  entry.purchaseCurrency.toUpperCase() ==
                  item.purchaseCurrency.toUpperCase(),
            )
            .toList();
        final candidates = store.items
            .where((entry) => entry.id != item.id && entry.isActive)
            .toList();
        final usageDaily = [
          item,
          ...selectedCostItems,
        ].fold<double>(0, (sum, entry) => sum + entry.usageDailyCost);
        final ownedDaily = [
          item,
          ...selectedCostItems,
        ].fold<double>(0, (sum, entry) => sum + entry.ownedDailyCost);
        return PageFrame(
          title: '关联物品',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMBINATION',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      '把一起使用的物品关联起来，查看组合后的真实使用成本。',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: MiniMetric(
                            label: '关联物品',
                            value: '${_selected.length}',
                            dark: true,
                          ),
                        ),
                        Expanded(
                          child: MiniMetric(
                            label: '使用日均',
                            value:
                                '${item.currencySymbol}${formatMoney(usageDaily)}',
                            dark: true,
                          ),
                        ),
                        Expanded(
                          child: MiniMetric(
                            label: '拥有日均',
                            value:
                                '${item.currencySymbol}${formatMoney(ownedDaily)}',
                            dark: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SectionHeading(title: '已关联'),
              if (selectedItems.isEmpty)
                const EmptyState(
                  title: '还没有组合伙伴',
                  description: '从下方选择经常一起使用的物品。',
                  icon: Icons.hub_outlined,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final related in selectedItems)
                      InputChip(
                        avatar: const Icon(
                          Icons.inventory_2_outlined,
                          size: 15,
                        ),
                        label: Text(related.name),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ItemDetailScreen(itemId: related.id),
                          ),
                        ),
                        onDeleted: () =>
                            setState(() => _selected.remove(related.id)),
                      ),
                  ],
                ),
              const SectionHeading(title: '可选择物品'),
              if (candidates.isEmpty)
                const EmptyState(
                  title: '暂无其他物品',
                  description: '再放入几件物品后，就可以建立组合关系。',
                  icon: Icons.inventory_2_outlined,
                )
              else
                SoftCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < candidates.length;
                        index++
                      ) ...[
                        _RelationCandidate(
                          item: candidates[index],
                          selected: _selected.contains(candidates[index].id),
                          onChanged: (selected) {
                            setState(() {
                              if (selected) {
                                _selected.add(candidates[index].id);
                              } else {
                                _selected.remove(candidates[index].id);
                              }
                            });
                          },
                        ),
                        if (index < candidates.length - 1)
                          const Divider(
                            height: 1,
                            indent: 58,
                            color: Color(0xFFF1EDE7),
                          ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _saving ? '保存中…' : '保存关联关系',
                icon: Icons.link_rounded,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AppStore.instance.setRelatedItems(widget.itemId, _selected);
      if (!mounted) return;
      Navigator.maybePop(context);
      showAppSnack(context, '关联关系已更新');
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _RelationCandidate extends StatelessWidget {
  const _RelationCandidate({
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final InventoryItem item;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: (value) => onChanged(value == true),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      secondary: ItemVisual(item: item, size: 42, radius: 12),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${item.categoryInfo.name} · ${item.statusInfo.name}',
        style: const TextStyle(color: appMuted, fontSize: 10),
      ),
    );
  }
}
