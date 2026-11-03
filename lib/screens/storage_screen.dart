import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/filter_pill_bar.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final _search = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final store = AppStore.instance;
        final keyword = _search.text.trim().toLowerCase();
        final matched = store.items.where((item) {
          final location = item.storageLocation.isEmpty
              ? '未设置位置'
              : item.storageLocation;
          final matchesFilter = _filter == 'all' || location == _filter;
          final matchesSearch =
              keyword.isEmpty ||
              item.name.toLowerCase().contains(keyword) ||
              item.categoryInfo.name.contains(keyword) ||
              location.toLowerCase().contains(keyword) ||
              item.tags.any((tag) => tag.toLowerCase().contains(keyword));
          return matchesFilter && matchesSearch;
        }).toList();
        final Map<String, List<InventoryItem>> groups = {};
        for (final item in matched) {
          final location = item.storageLocation.isEmpty
              ? '未设置位置'
              : item.storageLocation;
          groups.putIfAbsent(location, () => []).add(item);
        }
        final locations = [
          'all',
          ...store.storageLocations,
          if (groups.containsKey('未设置位置')) '未设置位置',
        ];
        return PageFrame(
          title: '收纳屋',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_filter != 'all' && _filter != '未设置位置') ...[
                IconButton(
                  onPressed: _renameCurrentLocation,
                  tooltip: '重命名当前位置',
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: _deleteCurrentLocation,
                  tooltip: '删除当前位置',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFC6657D),
                  ),
                ),
              ],
              IconButton.filledTonal(
                onPressed: _addLocation,
                tooltip: '新增收纳位置',
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索物品、位置、分类或标签',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              FilterPillBar<String>(
                value: _filter,
                onChanged: (value) => setState(() => _filter = value),
                height: 41,
                fontSize: 10,
                padding: EdgeInsets.zero,
                options: [
                  for (final location in locations)
                    FilterPillOption(
                      value: location,
                      label: location == 'all' ? '全部' : location,
                      color: appPrimary,
                      backgroundColor: const Color(0xFFE7F6F1),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (groups.isEmpty)
                EmptyState(
                  title: store.items.isEmpty ? '收纳屋还是空的' : '没有找到对应物品',
                  description: store.items.isEmpty
                      ? '为物品填写收纳位置后，会在这里自动归档。'
                      : '换个关键词或位置试试。',
                  icon: Icons.home_work_outlined,
                )
              else
                for (final entry in groups.entries) ...[
                  _LocationGroup(
                    location: entry.key,
                    items: entry.value,
                    onEdit: (item) => _changeLocation(item),
                  ),
                  const SizedBox(height: 13),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeLocation(InventoryItem item) async {
    final location = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              for (final location in [
                '',
                ...AppStore.instance.storageLocations,
              ])
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      location.isEmpty
                          ? Icons.layers_clear_outlined
                          : Icons.place_outlined,
                      color: location == item.storageLocation
                          ? appPrimary
                          : appMuted,
                    ),
                    title: Text(location.isEmpty ? '不设置位置' : location),
                    trailing: location == item.storageLocation
                        ? const Icon(Icons.check_rounded, color: appPrimary)
                        : null,
                    onTap: () => Navigator.pop(context, location),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (location != null) {
      if (!mounted) return;
      await runStoreAction(
        context,
        () => AppStore.instance.updateItem(
          item.copyWith(storageLocation: location),
        ),
      );
    }
  }

  Future<void> _addLocation() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增收纳位置'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          decoration: const InputDecoration(hintText: '例如：书房抽屉'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    if (!mounted) return;
    final added = await runStoreAction(
      context,
      () => AppStore.instance.addStorageLocation(name),
      successMessage: '收纳位置已添加',
    );
    if (added && mounted) setState(() => _filter = name.trim());
  }

  Future<void> _renameCurrentLocation() async {
    final controller = TextEditingController(text: _filter);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名收纳位置'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 12,
          decoration: const InputDecoration(hintText: '请输入新名称'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !mounted) return;
    final oldName = _filter;
    final renamed = await runStoreAction(
      context,
      () => AppStore.instance.renameStorageLocation(oldName, name),
      successMessage: '收纳位置已重命名',
    );
    if (renamed && mounted) setState(() => _filter = name.trim());
  }

  Future<void> _deleteCurrentLocation() async {
    final name = _filter;
    final confirmed = await confirmAction(
      context,
      title: '删除收纳位置',
      message: '删除“$name”后，其中的物品会变为未设置位置。',
      confirmLabel: '删除',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final deleted = await runStoreAction(
      context,
      () => AppStore.instance.deleteStorageLocation(name),
      successMessage: '收纳位置已删除',
    );
    if (deleted && mounted) setState(() => _filter = 'all');
  }
}

class _LocationGroup extends StatelessWidget {
  const _LocationGroup({
    required this.location,
    required this.items,
    required this.onEdit,
  });

  final String location;
  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onEdit;

  @override
  Widget build(BuildContext context) {
    final unassigned = location == '未设置位置';
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: unassigned
                      ? const Color(0xFFF1EEE9)
                      : const Color(0xFFE7F5F2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  unassigned
                      ? Icons.help_outline_rounded
                      : Icons.place_outlined,
                  color: unassigned ? appMuted : appPrimary,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} 件',
                style: const TextStyle(color: appMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ItemDetailScreen(itemId: items[i].id),
                ),
              ),
              onLongPress: () => onEdit(items[i]),
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    ItemVisual(item: items[i], size: 45, radius: 13),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        items[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onEdit(items[i]),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 17,
                        color: appPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              const Divider(height: 1, color: Color(0xFFF2EEE8)),
          ],
        ],
      ),
    );
  }
}
