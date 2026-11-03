import 'package:flutter/material.dart';

import '../app.dart';
import '../app_store.dart';
import '../components/home_asset_summary.dart';
import '../components/home_insight_card.dart';
import '../components/icon_shortcut.dart';
import '../components/item_list_card.dart';
import '../domain/home_insight.dart';
import '../models.dart';
import '../services/app_update_service.dart';
import '../services/cloud_sync_service.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';
import 'login_screen.dart';
import 'recovery_screen.dart';
import 'storage_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppUpdateService().checkAndShow(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final items = store.items;
    final insight = buildHomeInsight(items, store.wishlist);
    final idleValue = items
        .where((item) => item.status == 'idle')
        .fold<double>(0, (sum, item) => sum + item.currentTotal);
    return AppBackdrop(
      child: SafeArea(
        bottom: false,
        child: ContentPane(
          child: RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 116),
              children: [
                HomeAssetSummary(
                  totalValue: store.totalCurrentValue,
                  ownedDailyCost: store.totalOwnedDaily,
                  idleValue: idleValue,
                  totalCount: items.length,
                  inUseCount: store.countByStatus('inuse'),
                  idleCount: store.countByStatus('idle'),
                  isGuest: store.isGuest,
                  onStatusTap: (filter) =>
                      MainShell.of(context).openItemsFilter(filter),
                  onAccountTap: () {
                    if (store.isGuest) {
                      _openLogin(context);
                    } else {
                      MainShell.of(context).selectTab(3);
                    }
                  },
                ),
                const SizedBox(height: 16),
                HomeInsightCard(
                  type: insight.type,
                  title: insight.title,
                  message: insight.message,
                  onTap: () => _handleInsight(context, insight),
                ),
                const SectionHeading(title: '生活入口'),
                _QuickActions(
                  onStorage: () => _push(context, const StorageScreen()),
                  onWishlist: () => _push(context, const WishlistScreen()),
                  onRecovery: () => _push(context, const RecoveryScreen()),
                ),
                SectionHeading(
                  title: '最近放入',
                  trailing: TextButton(
                    onPressed: () =>
                        MainShell.of(context).openItemsFilter('all'),
                    child: const Text('查看全部'),
                  ),
                ),
                if (items.isEmpty)
                  EmptyState(
                    title: '收纳匣还是空的',
                    description: '从第一件值得被记住的物品开始。',
                    action: PrimaryButton(
                      label: '添加第一件物品',
                      icon: Icons.add_rounded,
                      expanded: false,
                      onPressed: () => MainShell.of(context).openAddItem(),
                    ),
                  )
                else
                  for (final item in items.take(3)) ...[
                    ItemListCard(
                      item: item,
                      onTap: () => _openDetail(context, item),
                      onLongPress: () => _showRecentActions(context, item),
                    ),
                    const SizedBox(height: 11),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final store = AppStore.instance;
    if (store.isGuest) {
      await store.expireGuestDataIfNeeded();
      return;
    }
    try {
      final service = CloudSyncService();
      final result = await service.loadAccountData(
        phone: store.accountPhone,
        token: store.sessionToken,
      );
      service.close();
      await store.applyCloudRefresh(result);
      if (context.mounted) showAppSnack(context, '云端数据已更新');
    } catch (error) {
      if (context.mounted) {
        showAppSnack(
          context,
          '同步失败，已保留本机数据：${error.toString().replaceFirst('Bad state: ', '')}',
        );
      }
    }
  }

  void _handleInsight(BuildContext context, HomeInsight insight) {
    if (insight.action == 'recovery') {
      _push(context, const RecoveryScreen());
      return;
    }
    if (insight.action == 'wishlist') {
      _push(context, const WishlistScreen());
      return;
    }
    if (insight.action == 'add') {
      MainShell.of(context).openAddItem();
      return;
    }
    if (insight.action == 'detail' && insight.itemId != null) {
      final item = AppStore.instance.itemById(insight.itemId!);
      if (item != null) _openDetail(context, item);
      return;
    }
    MainShell.of(context).openItemsFilter('all');
  }

  Future<void> _openLogin(BuildContext context) async {
    final synced = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const LoginScreen()));
    if (synced == true && context.mounted) {
      showAppSnack(context, '游客数据已同步到云端，本机游客副本已清理');
    }
  }

  Future<void> _showRecentActions(
    BuildContext context,
    InventoryItem item,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1DCD5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('查看详情'),
                onTap: () => Navigator.pop(sheetContext, 'detail'),
              ),
              if (item.usageMode == 'manual')
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.add_task_rounded,
                    color: appPrimary,
                  ),
                  title: const Text('记录一次使用'),
                  subtitle: Text(
                    '当前已记录 ${item.manualUsageCount} 次',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'use'),
                ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'detail') {
      _openDetail(context, item);
    } else if (action == 'use') {
      await runStoreAction(
        context,
        () => AppStore.instance.incrementUsage(item.id, 1),
        successMessage: '已记录一次使用',
      );
    }
  }

  void _openDetail(BuildContext context, InventoryItem item) {
    _push(context, ItemDetailScreen(itemId: item.id));
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onStorage,
    required this.onWishlist,
    required this.onRecovery,
  });

  final VoidCallback onStorage;
  final VoidCallback onWishlist;
  final VoidCallback onRecovery;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
      child: Row(
        children: [
          Expanded(
            child: IconShortcut(
              icon: Icons.home_work_outlined,
              label: '收纳屋',
              color: const Color(0xFF4B9F91),
              backgroundColor: const Color(0xFFE7F5F2),
              onTap: onStorage,
            ),
          ),
          Expanded(
            child: IconShortcut(
              icon: Icons.favorite_border_rounded,
              label: '心愿匣',
              color: const Color(0xFFC6657D),
              backgroundColor: const Color(0xFFFAEDF2),
              onTap: onWishlist,
            ),
          ),
          Expanded(
            child: IconShortcut(
              icon: Icons.recycling_rounded,
              label: '回血计划',
              color: const Color(0xFFC28B35),
              backgroundColor: const Color(0xFFFBF3DF),
              onTap: onRecovery,
            ),
          ),
        ],
      ),
    );
  }
}
