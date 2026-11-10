import 'package:flutter/material.dart';

import '../app.dart';
import '../app_store.dart';
import '../components/app_search_field.dart';
import '../components/guest_page_banner.dart';
import '../domain/item_display.dart';
import '../domain/items_browse.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';
import 'login_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key, this.store});

  final AppStore? store;

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _galleryController = ScrollController();
  final ScrollController _ledgerController = ScrollController();
  final ScrollController _locationController = ScrollController();
  String _keyword = '';
  ItemsBrowseMode _mode = ItemsBrowseMode.gallery;
  String? _knownFirstItemId;

  AppStore get _store => widget.store ?? AppStore.instance;

  @override
  void initState() {
    super.initState();
    final items = _store.items;
    _knownFirstItemId = items.isEmpty ? null : items.first.id;
    _store.addListener(_handleStoreChanged);
  }

  void _handleStoreChanged() {
    final items = _store.items;
    final firstId = items.isEmpty ? null : items.first.id;
    if (!mounted) return;
    final itemOrderChanged = firstId != _knownFirstItemId;
    _knownFirstItemId = firstId;
    setState(() {});
    if (!itemOrderChanged) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final controller in [
        _galleryController,
        _ledgerController,
        _locationController,
      ]) {
        if (controller.hasClients) controller.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _store.removeListener(_handleStoreChanged);
    _searchController.dispose();
    _galleryController.dispose();
    _ledgerController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final source = store.items.where((item) {
      final keyword = _keyword.trim().toLowerCase();
      return keyword.isEmpty || item.name.toLowerCase().contains(keyword);
    }).toList();
    return AppBackdrop(
      child: SafeArea(
        bottom: false,
        child: ContentPane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '匣中之物',
                      style: TextStyle(
                        fontFamily: 'Songti SC',
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '拾起日常，也看见它们各自的生活',
                      style: TextStyle(color: appMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (store.isGuest)
                GuestPageBanner(
                  margin: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                  subtitle: store.guestExpiryWarning
                      ? '本地数据即将到期 · 还可添加 '
                            '${store.guestAddsRemaining} 次'
                      : '物品保存在本机 · 还可添加 '
                            '${store.guestAddsRemaining} 次',
                  remainingAdds: store.guestAddsRemaining,
                  onLogin: _openLogin,
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, store.isGuest ? 8 : 20, 20, 8),
                child: AppSearchField(
                  controller: _searchController,
                  hintText: '搜索物品名称',
                  onChanged: (value) => setState(() => _keyword = value),
                ),
              ),
              _ItemsBrowseHeader(
                mode: _mode,
                onModeChanged: (mode) => setState(() => _mode = mode),
              ),
              Expanded(
                child: source.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                        children: [
                          EmptyState(
                            title: store.items.isEmpty
                                ? '还没有第一件匣中之物'
                                : '没有找到对应物品',
                            description: store.items.isEmpty
                                ? '把常用、喜欢或准备整理的物品记录下来。'
                                : '换一个关键词试试。',
                            action: PrimaryButton(
                              label:
                                  store.isGuest && store.guestAddsRemaining == 0
                                  ? '登录后继续添加'
                                  : '拾一件',
                              icon: Icons.add_rounded,
                              expanded: false,
                              onPressed: () =>
                                  MainShell.of(context).openAddItem(),
                            ),
                          ),
                        ],
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: switch (_mode) {
                          ItemsBrowseMode.gallery => _GalleryView(
                            key: const ValueKey('items-gallery'),
                            items: source,
                            controller: _galleryController,
                            onTap: _openDetail,
                            onUsageChanged: (item, delta) =>
                                _store.incrementUsage(item.id, delta),
                          ),
                          ItemsBrowseMode.ledger => _LedgerView(
                            key: const ValueKey('items-ledger'),
                            items: source,
                            controller: _ledgerController,
                            onTap: _openDetail,
                            onUsageChanged: (item, delta) =>
                                _store.incrementUsage(item.id, delta),
                          ),
                          ItemsBrowseMode.location => _LocationView(
                            key: const ValueKey('items-location'),
                            items: source,
                            controller: _locationController,
                            onTap: _openDetail,
                            onUsageChanged: (item, delta) =>
                                _store.incrementUsage(item.id, delta),
                          ),
                        },
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

  Future<void> _openLogin() async {
    final synced = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const LoginScreen()));
    if (synced == true && mounted) {
      MainShell.of(context).selectTab(0);
      showAppSnack(context, '登录成功，本机记录继续保存在当前设备');
    }
  }
}

class _ItemsBrowseHeader extends StatelessWidget {
  const _ItemsBrowseHeader({required this.mode, required this.onModeChanged});

  final ItemsBrowseMode mode;
  final ValueChanged<ItemsBrowseMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 7, 20, 11),
      child: _BrowseModeBar(value: mode, onChanged: onModeChanged),
    );
  }
}

class _BrowseModeBar extends StatelessWidget {
  const _BrowseModeBar({required this.value, required this.onChanged});

  final ItemsBrowseMode value;
  final ValueChanged<ItemsBrowseMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = AppThemeTokens.of(context).softPrimary;
    const icons = {
      ItemsBrowseMode.gallery: Icons.dashboard_customize_outlined,
      ItemsBrowseMode.ledger: Icons.view_agenda_outlined,
      ItemsBrowseMode.location: Icons.shelves,
    };
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        children: [
          for (final mode in ItemsBrowseMode.values)
            Expanded(
              child: InkWell(
                key: Key('items-view-${mode.iconName}'),
                onTap: () => onChanged(mode),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: mode == value ? softPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[mode],
                        size: 15,
                        color: mode == value ? primary : appMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        mode.label,
                        style: TextStyle(
                          color: mode == value ? primary : appMuted,
                          fontSize: 9,
                          fontWeight: mode == value
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryView extends StatelessWidget {
  const _GalleryView({
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
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 238,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = items[index];
              return _GalleryItemCard(
                item: item,
                onTap: () => onTap(item),
                onUsageChanged: (delta) => onUsageChanged(item, delta),
              );
            }, childCount: items.length),
          ),
        ),
      ],
    );
  }
}

class _GalleryItemCard extends StatelessWidget {
  const _GalleryItemCard({
    required this.item,
    required this.onTap,
    required this.onUsageChanged,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final Future<void> Function(int delta) onUsageChanged;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      radius: 21,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ItemPhoto(
                        item: item,
                        height: constraints.maxHeight,
                        radius: 0,
                      ),
                      Positioned(
                        left: 8,
                        right: item.favorite ? 38 : 8,
                        top: 8,
                        child: Row(
                          children: [
                            StatusPill(status: item.statusInfo, compact: true),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _ItemCategoryTag(
                                  category: item.categoryInfo.name,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.favorite)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: appPink,
                              size: 13,
                            ),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 24, 10, 9),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.58),
                              ],
                            ),
                          ),
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: item.usageMode == 'manual' ? 62 : 44,
            child: item.usageMode == 'manual'
                ? _ManualUsageActionPanel(
                    key: Key('gallery-manual-panel-${item.id}'),
                    costKey: Key('gallery-usage-cost-${item.id}'),
                    stepperKey: Key('gallery-manual-stepper-${item.id}'),
                    width: double.infinity,
                    alignment: Alignment.centerRight,
                    item: item,
                    onUsageChanged: onUsageChanged,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _itemContext(item, includeUsageCost: false),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: appMuted,
                                fontSize: 9,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _UsageAverageBadge(
                            item: item,
                            alignment: Alignment.centerRight,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _UsageAverageBadge extends StatelessWidget {
  const _UsageAverageBadge({
    super.key,
    required this.item,
    this.alignment = Alignment.centerLeft,
  });

  final InventoryItem item;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final amount = '${item.currencySymbol}${formatMoney(item.usageDailyCost)}';
    final unit = item.usageMode == 'manual' ? '次' : '天';
    return Align(
      alignment: alignment,
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
                style: const TextStyle(
                  color: appMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}

class _ItemCategoryTag extends StatelessWidget {
  const _ItemCategoryTag({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: appMuted,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ManualUsageActionPanel extends StatelessWidget {
  const _ManualUsageActionPanel({
    super.key,
    required this.costKey,
    required this.stepperKey,
    required this.item,
    required this.onUsageChanged,
    this.width,
    this.alignment = Alignment.centerLeft,
  });

  final Key costKey;
  final Key stepperKey;
  final InventoryItem item;
  final Future<void> Function(int delta) onUsageChanged;
  final double? width;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final alignRight = alignment == Alignment.centerRight;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _UsageAverageBadge(key: costKey, item: item, alignment: alignment),
          const SizedBox(height: 4),
          _ManualUsageStepper(
            key: stepperKey,
            itemId: item.id,
            count: item.manualUsageCount,
            onDecrement: item.manualUsageCount <= 0
                ? null
                : () => runStoreAction(context, () => onUsageChanged(-1)),
            onIncrement: () => runStoreAction(
              context,
              () => onUsageChanged(1),
              successMessage: '已记录一次使用',
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualUsageStepper extends StatelessWidget {
  const _ManualUsageStepper({
    super.key,
    required this.itemId,
    required this.count,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String itemId;
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
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
            tooltip: '减少一次使用记录',
            onTap: onDecrement,
          ),
          Expanded(
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
          _UsageStepButton(
            key: Key('manual-usage-increment-$itemId'),
            icon: Icons.add_rounded,
            tooltip: '记录一次使用',
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _UsageStepButton extends StatelessWidget {
  const _UsageStepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 30,
          height: 28,
          child: Icon(
            icon,
            size: 15,
            color: onTap == null ? appMuted.withValues(alpha: 0.35) : primary,
          ),
        ),
      ),
    );
  }
}

class _LedgerView extends StatelessWidget {
  const _LedgerView({
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
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _LedgerItemCard(
          item: item,
          onTap: () => onTap(item),
          onUsageChanged: (delta) => onUsageChanged(item, delta),
        );
      },
    );
  }
}

class _LedgerItemCard extends StatelessWidget {
  const _LedgerItemCard({
    required this.item,
    required this.onTap,
    required this.onUsageChanged,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final Future<void> Function(int delta) onUsageChanged;

  @override
  Widget build(BuildContext context) {
    final recent = recentUseText(item);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemVisual(item: item, size: 66, radius: 17),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(status: item.statusInfo, compact: true),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _itemMetadata(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appMuted, fontSize: 9),
                ),
                if (item.usageMode != 'manual') ...[
                  const SizedBox(height: 3),
                  Text(
                    _itemUsageDaysText(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: appMuted, fontSize: 9),
                  ),
                ],
                if (recent != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    recent,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: appMuted, fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: item.usageMode == 'manual'
                ? _ManualUsageActionPanel(
                    key: Key('ledger-manual-panel-${item.id}'),
                    costKey: Key('ledger-usage-cost-${item.id}'),
                    stepperKey: Key('ledger-manual-stepper-${item.id}'),
                    width: 96,
                    alignment: Alignment.centerRight,
                    item: item,
                    onUsageChanged: onUsageChanged,
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: _UsageAverageBadge(
                      item: item,
                      alignment: Alignment.centerRight,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocationView extends StatelessWidget {
  const _LocationView({
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
        return _LocationGroupCard(
          group: group,
          onItemTap: onTap,
          onUsageChanged: onUsageChanged,
        );
      },
    );
  }
}

class _LocationGroupCard extends StatelessWidget {
  const _LocationGroupCard({
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
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Color.lerp(primary, Colors.white, 0.88),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  unassigned
                      ? Icons.layers_clear_outlined
                      : Icons.place_outlined,
                  color: unassigned ? appMuted : primary,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.location,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${group.items.length} 件',
                style: const TextStyle(color: appMuted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 9),
          for (var index = 0; index < group.items.length; index++) ...[
            _LocationItemRow(
              item: group.items[index],
              onTap: () => onItemTap(group.items[index]),
              onUsageChanged: (delta) =>
                  onUsageChanged(group.items[index], delta),
            ),
            if (index < group.items.length - 1)
              const Divider(height: 1, indent: 54, color: Color(0xFFF2EEE8)),
          ],
        ],
      ),
    );
  }
}

class _LocationItemRow extends StatelessWidget {
  const _LocationItemRow({
    required this.item,
    required this.onTap,
    required this.onUsageChanged,
  });

  final InventoryItem item;
  final VoidCallback onTap;
  final Future<void> Function(int delta) onUsageChanged;

  @override
  Widget build(BuildContext context) {
    final recent = recentUseText(item);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              ItemVisual(item: item, size: 44, radius: 12),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(status: item.statusInfo, compact: true),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.categoryInfo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: appMuted, fontSize: 9),
                    ),
                    const SizedBox(height: 3),
                    if (item.usageMode != 'manual') ...[
                      Row(
                        children: [
                          if (recent != null)
                            Expanded(
                              child: Text(
                                recent,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: appMuted,
                                  fontSize: 9,
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 6),
                          _UsageAverageBadge(
                            item: item,
                            alignment: Alignment.centerRight,
                          ),
                        ],
                      ),
                    ] else if (recent != null)
                      Text(
                        recent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: appMuted, fontSize: 9),
                      ),
                  ],
                ),
              ),
              if (item.usageMode == 'manual') ...[
                const SizedBox(width: 8),
                _ManualUsageActionPanel(
                  key: Key('location-manual-panel-${item.id}'),
                  costKey: Key('location-usage-cost-${item.id}'),
                  stepperKey: Key('location-manual-stepper-${item.id}'),
                  width: 96,
                  alignment: Alignment.centerRight,
                  item: item,
                  onUsageChanged: onUsageChanged,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _itemMetadata(InventoryItem item) {
  final location = item.storageLocation.trim().isEmpty
      ? '待安放'
      : item.storageLocation.trim();
  return '${item.categoryInfo.name} · $location';
}

String _itemUsageDaysText(InventoryItem item) {
  return item.usageMode == 'manual'
      ? '已记录 ${item.manualUsageCount} 次'
      : '已使用 ${item.usageDays} 天';
}

String _itemContext(InventoryItem item, {bool includeUsageCost = true}) {
  return switch (item.status) {
    'idle' when item.hasRecoveryPlan =>
      '${item.recoveryMethod}计划 · '
          '${item.recoveryDeadline.isEmpty ? '待完成' : '${item.recoveryDeadline} 前'}',
    'idle' =>
      '闲置 ${item.idleDays} 天 · 参考回血 '
          '${item.currencySymbol}${formatMoney(item.recoveryEstimateLow, compact: true)}'
          '–${item.currencySymbol}${formatMoney(item.recoveryEstimateHigh, compact: true)}',
    'repairing' =>
      item.repairDays > 0
          ? '预计维修 ${item.repairDays} 天 · 等待重新回到生活'
          : '正在维修 · 等待重新回到生活',
    _ when item.usageMode == 'manual' =>
      '已记录 ${item.manualUsageCount} 次 · 最近使用',
    _ when includeUsageCost =>
      '已使用 ${item.usageDays} 天 · '
          '${item.currencySymbol}${formatMoney(item.usageDailyCost)}/天',
    _ => '已使用 ${item.usageDays} 天',
  };
}
