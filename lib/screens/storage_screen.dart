import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/app_search_field.dart';
import '../components/page_action_button.dart';
import '../components/storage/storage_item_card.dart';
import '../components/storage/storage_overview_card.dart';
import '../components/storage/storage_space_card.dart';
import '../components/storage/storage_unassigned_inbox.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';

Future<String?> showLocationNameDialog(
  BuildContext context, {
  required String title,
  required String hintText,
  required String confirmLabel,
  String initialValue = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => LocationNameDialog(
      title: title,
      hintText: hintText,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
    ),
  );
}

class LocationNameDialog extends StatefulWidget {
  const LocationNameDialog({
    super.key,
    required this.title,
    required this.hintText,
    required this.confirmLabel,
    this.initialValue = '',
  });

  final String title;
  final String hintText;
  final String confirmLabel;
  final String initialValue;

  @override
  State<LocationNameDialog> createState() => _LocationNameDialogState();
}

class _LocationNameDialogState extends State<LocationNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 12,
        decoration: InputDecoration(hintText: widget.hintText),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

Future<String?> showLocationPicker(
  BuildContext context,
  InventoryItem item, {
  List<String>? locations,
}) {
  final availableLocations = [
    '',
    ...(locations ?? AppStore.instance.storageLocations),
  ];
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final primary = Theme.of(sheetContext).colorScheme.primary;
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: const Color(0xFFE0DCD5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '更改「${item.name}」的位置',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: availableLocations.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 42,
                      color: Color(0xFFF2EEE8),
                    ),
                    itemBuilder: (context, index) {
                      final location = availableLocations[index];
                      final selected = location == item.storageLocation;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            location.isEmpty
                                ? Icons.layers_clear_outlined
                                : Icons.place_outlined,
                            color: selected ? primary : appMuted,
                          ),
                          title: Text(location.isEmpty ? '不设置位置' : location),
                          trailing: selected
                              ? Icon(Icons.check_rounded, color: primary)
                              : null,
                          onTap: () => Navigator.pop(context, location),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key, this.store});

  final AppStore? store;

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store ?? AppStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final keyword = _search.text.trim().toLowerCase();
        final assignedItems = store.items
            .where((item) => item.storageLocation.trim().isNotEmpty)
            .toList();
        final allLocations = <String>{
          ...store.storageLocations,
          ...assignedItems.map((item) => item.storageLocation.trim()),
        }.toList();
        final itemCountByLocation = <String, int>{};
        for (final item in assignedItems) {
          final location = item.storageLocation.trim();
          itemCountByLocation[location] =
              (itemCountByLocation[location] ?? 0) + 1;
        }
        final matching = store.items.where((item) {
          final location = item.storageLocation.trim().isEmpty
              ? '未设置位置'
              : item.storageLocation.trim();
          return keyword.isEmpty ||
              item.name.toLowerCase().contains(keyword) ||
              item.categoryInfo.name.toLowerCase().contains(keyword) ||
              location.toLowerCase().contains(keyword) ||
              item.tags.any((tag) => tag.toLowerCase().contains(keyword));
        }).toList();
        final groups = <String, List<InventoryItem>>{};
        for (final item in matching) {
          final location = item.storageLocation.trim().isEmpty
              ? '未设置位置'
              : item.storageLocation.trim();
          (groups[location] ??= []).add(item);
        }
        final unassigned = groups.remove('未设置位置') ?? const <InventoryItem>[];
        final visibleLocations =
            keyword.isEmpty
                  ? List<String>.from(allLocations)
                  : allLocations.where((location) {
                      return location.toLowerCase().contains(keyword) ||
                          (groups[location]?.isNotEmpty ?? false);
                    }).toList()
              ..sort((first, second) {
                final byCount = (itemCountByLocation[second] ?? 0).compareTo(
                  itemCountByLocation[first] ?? 0,
                );
                return byCount != 0 ? byCount : first.compareTo(second);
              });
        final hasSearchResults =
            unassigned.isNotEmpty || visibleLocations.isNotEmpty;
        final unassignedCount = store.items
            .where((item) => item.storageLocation.trim().isEmpty)
            .length;
        return PageFrame(
          title: '归处',
          action: PageActionButton(
            buttonKey: const Key('add-location-button'),
            tooltip: '添一处归处',
            label: '添归处',
            icon: Icons.add_rounded,
            onPressed: _addLocation,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                controller: _search,
                hintText: '搜索物品、位置、分类或标签',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              StorageOverviewCard(
                key: const Key('storage-overview'),
                locationCount: allLocations.length,
                placedCount: store.items.length - unassignedCount,
                unassignedCount: unassignedCount,
              ),
              if (store.items.isEmpty) ...[
                const SizedBox(height: 16),
                const EmptyState(
                  title: '归处图还空着',
                  description: '拾入物品并给它一个归处，空间地图会在这里慢慢形成。',
                  icon: Icons.home_work_outlined,
                ),
              ] else if (keyword.isNotEmpty && !hasSearchResults) ...[
                const SizedBox(height: 16),
                const EmptyState(
                  title: '没有找到对应物品',
                  description: '换一个关键词或空间名称试试。',
                  icon: Icons.search_off_rounded,
                ),
              ] else ...[
                if (unassigned.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  StorageUnassignedInbox(
                    key: const Key('storage-unassigned-inbox'),
                    items: unassigned,
                    totalCount: unassigned.length,
                    onTap: () => _openLocation('未设置位置'),
                  ),
                ],
                if (visibleLocations.isNotEmpty) ...[
                  SectionHeading(
                    title: '匣中归处',
                    trailing: Text(
                      '${visibleLocations.length} 处归处',
                      style: const TextStyle(color: appMuted, fontSize: 10),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 230,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 174,
                        ),
                    itemCount: visibleLocations.length,
                    itemBuilder: (context, index) {
                      final location = visibleLocations[index];
                      return StorageSpaceCard(
                        key: Key('storage-space-$location'),
                        location: location,
                        items: groups[location] ?? const [],
                        onTap: () => _openLocation(location),
                      );
                    },
                  ),
                ] else if (keyword.isEmpty) ...[
                  const SizedBox(height: 16),
                  const EmptyState(
                    title: '还没有归处',
                    description: '添第一处归处，让物品在地图上有自己的位置。',
                    icon: Icons.add_home_work_outlined,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _addLocation() async {
    final name = await showLocationNameDialog(
      context,
      title: '添一处归处',
      hintText: '例如：书房抽屉',
      confirmLabel: '添归处',
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    await runStoreAction(
      context,
      () => (widget.store ?? AppStore.instance).addStorageLocation(name),
      successMessage: '已添一处归处',
    );
  }

  void _openLocation(String location) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            StorageLocationScreen(location: location, store: widget.store),
      ),
    );
  }
}

class StorageLocationScreen extends StatefulWidget {
  const StorageLocationScreen({super.key, required this.location, this.store});

  final String location;
  final AppStore? store;

  @override
  State<StorageLocationScreen> createState() => _StorageLocationScreenState();
}

class _StorageLocationScreenState extends State<StorageLocationScreen> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store ?? AppStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final unassigned = widget.location == '未设置位置';
        final items = store.items
            .where(
              (item) => unassigned
                  ? item.storageLocation.trim().isEmpty
                  : item.storageLocation.trim() == widget.location.trim(),
            )
            .toList();
        final value = items
            .where((item) => item.isActive && item.canAggregateInBaseCurrency)
            .fold<double>(0, (sum, item) => sum + item.currentTotal);
        final hasForeignCurrency = items.any(
          (item) => item.isActive && !item.canAggregateInBaseCurrency,
        );
        final primary = Theme.of(context).colorScheme.primary;
        return PageFrame(
          title: widget.location,
          action: unassigned
              ? null
              : PopupMenuButton<String>(
                  tooltip: '空间操作',
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (action) {
                    if (action == 'rename') _renameLocation();
                    if (action == 'delete') _deleteLocation();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('重命名位置')),
                    PopupMenuItem(value: 'delete', child: Text('删除位置')),
                  ],
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SoftCard(
                color: Color.lerp(Colors.white, primary, 0.06)!,
                borderColor: primary.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    Icon(
                      unassigned
                          ? Icons.move_to_inbox_outlined
                          : storageLocationIcon(widget.location),
                      color: unassigned ? appMuted : primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${items.length} 件物品',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hasForeignCurrency
                                ? '人民币估值 ¥${formatMoney(value, compact: true)} · 另有外币物品'
                                : '当前估值 ¥${formatMoney(value, compact: true)}',
                            style: const TextStyle(
                              color: appMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (items.isNotEmpty)
                      Text(
                        '长按移动',
                        style: TextStyle(
                          color: primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                EmptyState(
                  title: unassigned ? '没有待安放的物品' : '这个空间还是空的',
                  description: unassigned
                      ? '所有物品都已经找到了自己的位置。'
                      : '把物品移入这里后，会自动出现在空间清单中。',
                  icon: unassigned
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_home_work_outlined,
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 192,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return StorageItemCard(
                      item: item,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ItemDetailScreen(itemId: item.id),
                        ),
                      ),
                      onMove: () => _changeLocation(item),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeLocation(InventoryItem item) async {
    final store = widget.store ?? AppStore.instance;
    final location = await showLocationPicker(
      context,
      item,
      locations: store.storageLocations,
    );
    if (location == null || !mounted) return;
    await runStoreAction(
      context,
      () => store.updateItem(item.copyWith(storageLocation: location)),
    );
  }

  Future<void> _renameLocation() async {
    final name = await showLocationNameDialog(
      context,
      title: '重命名收纳位置',
      hintText: '请输入新名称',
      confirmLabel: '保存',
      initialValue: widget.location,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final renamed = await runStoreAction(
      context,
      () => (widget.store ?? AppStore.instance).renameStorageLocation(
        widget.location,
        name,
      ),
      successMessage: '收纳位置已重命名',
    );
    if (renamed && mounted) Navigator.pop(context);
  }

  Future<void> _deleteLocation() async {
    final confirmed = await confirmAction(
      context,
      title: '删除收纳位置',
      message: '删除“${widget.location}”后，其中的物品会变为未设置位置。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final deleted = await runStoreAction(
      context,
      () => (widget.store ?? AppStore.instance).deleteStorageLocation(
        widget.location,
      ),
      successMessage: '收纳位置已删除',
    );
    if (deleted && mounted) Navigator.pop(context);
  }
}
