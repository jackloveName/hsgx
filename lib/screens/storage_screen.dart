import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/bottom_sheet_handle.dart';
import '../components/page_action_button.dart';
import '../components/storage/storage_item_card.dart';
import '../components/storage/storage_location_icons.dart';
import '../components/storage/storage_overview_card.dart';
import '../components/storage/storage_space_card.dart';
import '../components/storage/storage_unassigned_inbox.dart';
import '../models.dart';
import '../widgets.dart';

class StorageLocationDraft {
  const StorageLocationDraft({required this.name, required this.iconKey});

  final String name;
  final String iconKey;
}

Future<StorageLocationDraft?> showStorageLocationSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
  String initialIconKey = '',
}) {
  return showModalBottomSheet<StorageLocationDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StorageLocationSheet(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initialName,
      initialIconKey: initialIconKey,
    ),
  );
}

class _StorageLocationSheet extends StatefulWidget {
  const _StorageLocationSheet({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.initialIconKey,
  });

  final String title;
  final String confirmLabel;
  final String initialName;
  final String initialIconKey;

  @override
  State<_StorageLocationSheet> createState() => _StorageLocationSheetState();
}

class _StorageLocationSheetState extends State<_StorageLocationSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  late String _iconKey = widget.initialIconKey.trim().isEmpty
      ? storageLocationDefaultIconKey(widget.initialName)
      : widget.initialIconKey;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, StorageLocationDraft(name: name, iconKey: _iconKey));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final canSubmit = _controller.text.trim().isNotEmpty;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: BoxDecoration(
          color: context.appSurfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BottomSheetHandle(),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Songti SC',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('storage-location-name-field'),
                  controller: _controller,
                  autofocus: false,
                  maxLength: 12,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: '归处名称',
                    hintText: '例如：书房抽屉',
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),
                Text(
                  '图标',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in storageLocationIconOptions)
                      _StorageLocationIconChoice(
                        option: option,
                        selected: option.keyName == _iconKey,
                        onTap: () => setState(() => _iconKey = option.keyName),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        key: const Key('storage-location-submit'),
                        onPressed: canSubmit ? _submit : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          backgroundColor: primary,
                        ),
                        child: Text(widget.confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StorageLocationIconChoice extends StatelessWidget {
  const _StorageLocationIconChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final StorageLocationIconOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: Tooltip(
        message: option.label,
        child: InkWell(
          key: Key('storage-location-icon-${option.keyName}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: 0.1)
                  : context.appSurfaceMutedColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? primary.withValues(alpha: 0.55)
                    : context.appBorderColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Icon(
              option.icon,
              size: 21,
              color: selected ? primary : context.appMutedColor,
            ),
          ),
        ),
      ),
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
          decoration: BoxDecoration(
            color: sheetContext.appSurfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BottomSheetHandle(width: 40, height: 4),
                const SizedBox(height: 18),
                Text(
                  '更改「${item.name}」的位置',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: availableLocations.length,
                    separatorBuilder: (_, _) =>
                        const ContentDivider(indent: 42),
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
                            color: selected ? primary : context.appMutedColor,
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
  @override
  Widget build(BuildContext context) {
    final store = widget.store ?? AppStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
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
        final groups = <String, List<InventoryItem>>{};
        for (final item in store.items) {
          final location = item.storageLocation.trim().isEmpty
              ? '未设置位置'
              : item.storageLocation.trim();
          (groups[location] ??= []).add(item);
        }
        final unassigned = groups.remove('未设置位置') ?? const <InventoryItem>[];
        final visibleLocations = List<String>.from(allLocations)
          ..sort((first, second) {
            final byCount = (itemCountByLocation[second] ?? 0).compareTo(
              itemCountByLocation[first] ?? 0,
            );
            return byCount != 0 ? byCount : first.compareTo(second);
          });
        final unassignedCount = store.items
            .where((item) => item.storageLocation.trim().isEmpty)
            .length;
        return PageFrame.slivers(
          title: '归处',
          action: PageActionButton(
            buttonKey: const Key('add-location-button'),
            tooltip: '添一处归处',
            label: '添归处',
            icon: Icons.add_rounded,
            onPressed: _addLocation,
          ),
          slivers: [
            SliverToBoxAdapter(
              child: StorageOverviewCard(
                key: const Key('storage-overview'),
                locationCount: allLocations.length,
                placedCount: store.items.length - unassignedCount,
                unassignedCount: unassignedCount,
              ),
            ),
            if (store.items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: EmptyState(
                    title: '归处图还空着',
                    description: '拾入物品并给它一个归处，空间地图会在这里慢慢形成。',
                    icon: Icons.home_work_outlined,
                  ),
                ),
              )
            else ...[
              if (unassigned.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: StorageUnassignedInbox(
                      key: const Key('storage-unassigned-inbox'),
                      items: unassigned,
                      totalCount: unassigned.length,
                      onTap: () => _openLocation('未设置位置'),
                    ),
                  ),
                ),
              if (visibleLocations.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SectionHeading(title: '匣中归处')),
                SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
                      iconKey: store.storageLocationIconKey(location),
                      items: groups[location] ?? const [],
                      onTap: () => _openLocation(location),
                    );
                  },
                ),
              ] else
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: EmptyState(
                      title: '还没有归处',
                      description: '添第一处归处，让物品在地图上有自己的位置。',
                      icon: Icons.add_home_work_outlined,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _addLocation() async {
    final draft = await showStorageLocationSheet(
      context,
      title: '添一处归处',
      confirmLabel: '添归处',
    );
    if (draft == null || !mounted) return;
    await runStoreAction(
      context,
      () => (widget.store ?? AppStore.instance).addStorageLocation(
        draft.name,
        iconKey: draft.iconKey,
      ),
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
        return PageFrame.slivers(
          title: unassigned ? '设置归处' : widget.location,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          action: unassigned
              ? null
              : IconButton(
                  key: const Key('rename-location-button'),
                  tooltip: '重命名归处',
                  onPressed: _renameLocation,
                  icon: const Icon(Icons.edit_outlined),
                ),
          slivers: [
            if (items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  title: unassigned ? '没有待安放的物品' : '这个空间还是空的',
                  description: unassigned
                      ? '所有物品都已经找到了自己的位置。'
                      : '把物品移入这里后，会自动出现在空间清单中。',
                  icon: unassigned
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_home_work_outlined,
                ),
              )
            else
              SliverGrid.builder(
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
                    onTap: () => _changeLocation(item),
                  );
                },
              ),
            if (!unassigned)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  key: const Key('storage-location-footer'),
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('delete-location-button'),
                        onPressed: _deleteLocation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB75A70),
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          side: BorderSide(
                            color: const Color(0xFFB75A70)
                                .withValues(alpha: 0.28),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('删除此归处'),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
    final store = widget.store ?? AppStore.instance;
    final draft = await showStorageLocationSheet(
      context,
      title: '重命名归处',
      confirmLabel: '保存',
      initialName: widget.location,
      initialIconKey: store.storageLocationIconKey(widget.location),
    );
    if (draft == null || !mounted) return;
    final nameChanged = draft.name != widget.location;
    final renamed = await runStoreAction(
      context,
      () => store.renameStorageLocation(
        widget.location,
        draft.name,
        iconKey: draft.iconKey,
      ),
      successMessage: '收纳位置已重命名',
    );
    if (renamed && mounted && nameChanged) Navigator.pop(context);
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
