import 'package:flutter/material.dart';

import '../app.dart';
import '../app_store.dart';
import '../components/filter_pill_bar.dart';
import '../components/items_filter_controller.dart';
import '../components/item_list_card.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key, required this.filterController});

  final ItemsFilterController filterController;

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';
  bool _grid = true;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.filterController.value;
    widget.filterController.addListener(_applyExternalFilter);
  }

  void _applyExternalFilter() {
    if (!mounted) return;
    setState(() => _filter = widget.filterController.value);
  }

  @override
  void dispose() {
    widget.filterController.removeListener(_applyExternalFilter);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final source = store.items.where((item) {
      final matchesFilter = _filter == 'all' || item.status == _filter;
      final keyword = _keyword.trim().toLowerCase();
      final matchesSearch =
          keyword.isEmpty ||
          item.name.toLowerCase().contains(keyword) ||
          item.categoryInfo.name.contains(keyword) ||
          item.tags.any((tag) => tag.toLowerCase().contains(keyword));
      return matchesFilter && matchesSearch;
    }).toList();
    return AppBackdrop(
      child: SafeArea(
        bottom: false,
        child: ContentPane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _keyword = value),
                  decoration: InputDecoration(
                    hintText: '搜索名称、分类或标签',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _keyword.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _keyword = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                  ),
                ),
              ),
              FilterPillBar<String>(
                value: _filter,
                onChanged: (value) => setState(() => _filter = value),
                options: [
                  const FilterPillOption(
                    value: 'all',
                    label: '全部',
                    color: appBlue,
                    backgroundColor: Color(0xFFEDF2FB),
                  ),
                  for (final status in itemStatuses)
                    FilterPillOption(
                      value: status.id,
                      label: status.name,
                      color: status.color,
                      backgroundColor: status.softColor,
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(
                  children: [
                    Text(
                      '共 ${source.length} 件',
                      style: const TextStyle(color: appMuted, fontSize: 12),
                    ),
                    const Spacer(),
                    _ViewToggle(
                      selected: _grid,
                      icon: Icons.grid_view_rounded,
                      onTap: () => setState(() => _grid = true),
                    ),
                    const SizedBox(width: 6),
                    _ViewToggle(
                      selected: !_grid,
                      icon: Icons.view_agenda_outlined,
                      onTap: () => setState(() => _grid = false),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: source.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                        children: [
                          EmptyState(
                            title: store.items.isEmpty ? '还没有放入物品' : '没有找到对应物品',
                            description: store.items.isEmpty
                                ? '把常用、喜欢或准备整理的物品记录下来。'
                                : '换一个关键词或状态试试。',
                            action: PrimaryButton(
                              label: '添加物品',
                              icon: Icons.add_rounded,
                              expanded: false,
                              onPressed: () =>
                                  MainShell.of(context).openAddItem(),
                            ),
                          ),
                        ],
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _grid
                            ? GridView.builder(
                                key: const ValueKey('grid'),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  116,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 230,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.69,
                                    ),
                                itemCount: source.length,
                                itemBuilder: (context, index) {
                                  return _GridItem(
                                    item: source[index],
                                    onTap: () => _openDetail(source[index]),
                                  );
                                },
                              )
                            : ListView.separated(
                                key: const ValueKey('list'),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  116,
                                ),
                                itemCount: source.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 11),
                                itemBuilder: (context, index) {
                                  return ItemListCard(
                                    item: source[index],
                                    compactValue: false,
                                    onTap: () => _openDetail(source[index]),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(InventoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ItemDetailScreen(itemId: item.id),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE7F6F1) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? const Color(0xFFBFE1DA) : appBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: selected ? appPrimary : const Color(0xFF9B968E),
        ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({required this.item, required this.onTap});

  final InventoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      radius: 21,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    color: item.categoryInfo.softColor,
                    child: Center(
                      child: ItemVisual(item: item, size: 112, radius: 16),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: StatusPill(status: item.statusInfo, compact: true),
                ),
                if (item.favorite)
                  const Positioned(
                    right: 9,
                    top: 9,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: appPink,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.categoryInfo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appMuted, fontSize: 10),
                ),
              ),
              Text(
                '${item.currencySymbol}${formatMoney(item.currentTotal, compact: true)}',
                style: const TextStyle(
                  color: Color(0xFF2E7568),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (item.usageMode == 'manual') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _CountButton(
                  icon: Icons.remove_rounded,
                  onTap: () => runStoreAction(
                    context,
                    () => AppStore.instance.incrementUsage(item.id, -1),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${item.manualUsageCount} 次',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: appMuted),
                  ),
                ),
                _CountButton(
                  icon: Icons.add_rounded,
                  onTap: () => runStoreAction(
                    context,
                    () => AppStore.instance.incrementUsage(item.id, 1),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 26,
        height: 25,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F1ED),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 15),
      ),
    );
  }
}
