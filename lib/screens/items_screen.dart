import 'package:flutter/material.dart';

import '../app.dart';
import '../app_store.dart';
import '../components/app_search_field.dart';
import '../components/guest_page_banner.dart';
import '../components/items/items_browse_header.dart';
import '../components/items/items_gallery_view.dart';
import '../components/items/items_ledger_view.dart';
import '../components/items/items_location_view.dart';
import '../domain/items_browse.dart';
import '../models.dart';
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
                padding: EdgeInsets.fromLTRB(20, store.isGuest ? 8 : 14, 20, 8),
                child: AppSearchField(
                  controller: _searchController,
                  hintText: '搜索物品名称',
                  onChanged: (value) => setState(() => _keyword = value),
                ),
              ),
              ItemsBrowseHeader(
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
                          ItemsBrowseMode.gallery => ItemsGalleryView(
                            key: const ValueKey('items-gallery'),
                            items: source,
                            controller: _galleryController,
                            onTap: _openDetail,
                            onUsageChanged: (item, delta) =>
                                _store.incrementUsage(item.id, delta),
                          ),
                          ItemsBrowseMode.ledger => ItemsLedgerView(
                            key: const ValueKey('items-ledger'),
                            items: source,
                            controller: _ledgerController,
                            onTap: _openDetail,
                            onUsageChanged: (item, delta) =>
                                _store.incrementUsage(item.id, delta),
                          ),
                          ItemsBrowseMode.location => ItemsLocationView(
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
