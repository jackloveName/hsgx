import 'package:flutter/material.dart';

import '../app.dart';
import '../app_store.dart';
import '../components/home_daily_hero.dart';
import '../components/home_today_actions.dart';
import '../components/icon_shortcut.dart';
import '../components/local_data_status_banner.dart';
import '../components/recent_item_shelf.dart';
import '../domain/home_insight.dart';
import '../domain/items_browse.dart';
import '../models.dart';
import '../services/app_update_service.dart';
import '../services/cloud_sync_service.dart';
import '../theme.dart';
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
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final store = AppStore.instance;
        final items = store.items;
        final insight = buildHomeInsight(items, store.wishlist);
        final dailyItem = _dailyItem(store, insight);
        final recentPreview = recentItemsForHome(items);
        final todayActions = _todayActions(context, store, insight, dailyItem);
        return AppBackdrop(
          child: SafeArea(
            bottom: false,
            child: ContentPane(
              child: RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 116),
                  children: [
                    const LocalDataStatusBanner(
                      margin: EdgeInsets.only(bottom: 12),
                    ),
                    if (store.isGuest) ...[
                      _HomeHeader(
                        guestAddsRemaining: store.guestAddsRemaining,
                        onLogin: () => _openLogin(context),
                      ),
                      const SizedBox(height: 12),
                    ],
                    HomeDailyHero(
                      item: dailyItem,
                      title: dailyItem?.name ?? '从第一件美好开始',
                      message: _dailyMessage(dailyItem, insight),
                      actionLabel: _dailyActionLabel(dailyItem, insight),
                      onAction: dailyItem == null
                          ? () => MainShell.of(context).openAddItem()
                          : () =>
                                _handleDailyAction(context, dailyItem, insight),
                    ),
                    if (todayActions.isNotEmpty) ...[
                      const SectionHeading(title: '今天可以这样与匣相处'),
                      HomeTodayActions(actions: todayActions),
                    ],
                    const SectionHeading(title: '匣中去处'),
                    _QuickActions(
                      onStorage: () => _push(context, const StorageScreen()),
                      onWishlist: () => _push(context, const WishlistScreen()),
                      onRecovery: () => _push(context, const RecoveryScreen()),
                    ),
                    if (items.isNotEmpty) ...[
                      const SectionHeading(title: '匣中常在'),
                      RecentItemShelf(
                        items: recentPreview,
                        onTap: (item) => _openDetail(context, item),
                      ),
                    ] else ...[
                      const SectionHeading(title: '记录之后，你会看到'),
                      const _FirstRecordGuide(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final store = AppStore.instance;
    if (store.isGuest) {
      await store.expireGuestDataIfNeeded();
      return;
    }
    if (store.cloudSyncPending || store.isSaving) return;
    CloudSyncService? service;
    try {
      final revision = store.dataRevision;
      service = CloudSyncService(
        onUnauthorized: AppStore.instance.handleUnauthorized,
      );
      final result = await service.loadAccountData(
        phone: store.accountPhone,
        token: store.sessionToken,
      );
      if (store.cloudSyncPending ||
          store.isSaving ||
          store.dataRevision != revision) {
        return;
      }
      await store.applyCloudRefresh(result, expectedRevision: revision);
    } catch (error) {
      if (context.mounted) {
        showAppSnack(
          context,
          '刷新失败，已保留本机数据：${error.toString().replaceFirst('Bad state: ', '')}',
        );
      }
    } finally {
      service?.close();
    }
  }

  InventoryItem? _dailyItem(AppStore store, HomeInsight insight) {
    if (insight.itemId != null) {
      final matched = store.itemById(insight.itemId!);
      if (matched != null) return matched;
    }
    final items = store.items
        .where(
          (item) => const ['inuse', 'idle', 'repairing'].contains(item.status),
        )
        .toList();
    if (items.isEmpty) return null;
    items.sort((first, second) {
      if (first.favorite != second.favorite) return first.favorite ? -1 : 1;
      final firstUsed = first.lastUsedAt;
      final secondUsed = second.lastUsedAt;
      if (firstUsed != null || secondUsed != null) {
        if (firstUsed == null) return 1;
        if (secondUsed == null) return -1;
        final byUse = secondUsed.compareTo(firstUsed);
        if (byUse != 0) return byUse;
      }
      return second.ownedDays.compareTo(first.ownedDays);
    });
    return items.first;
  }

  String _dailyMessage(InventoryItem? item, HomeInsight insight) {
    if (item == null) {
      return '选一件每天都会用到的东西，拍张照片。让使用时间、成本和陪伴，从今天开始有迹可循。';
    }
    if (insight.itemId == item.id) {
      return _withoutItemPrefix(insight.message, item.name);
    }
    final location = item.storageLocation.trim().isEmpty
        ? '你的收纳匣'
        : item.storageLocation;
    return switch (item.status) {
      'idle' => '它在 $location 安静待了 ${item.idleDays} 天。今天可以重新用一次，也可以给它一个新去处。',
      'repairing' =>
        item.repairDays > 0
            ? '它正在维修中，预计需要 ${item.repairDays} 天。记录这个过程，也算认真对待拥有。'
            : '它正在维修中。记录这个过程，也算认真对待拥有。',
      'processed' => '它已经结束陪伴，但那些被好好使用的日子值得留在记录里。',
      'retired' => '它已经从生活里退场，留下来的故事仍然可以被好好收藏。',
      _ when item.usageMode == 'manual' && item.usageDays > 0 =>
        '已陪伴 ${item.ownedDays} 天，累计使用 ${item.usageDays} 次。今天也可以再记录一次。',
      _ when item.usageDays > 0 =>
        '已陪伴 ${item.ownedDays} 天，累计使用 ${item.usageDays} 天。今天也让它继续参与生活。',
      _ => '已陪伴 ${item.ownedDays} 天。从一次使用记录开始，慢慢看见它真实的日常价值。',
    };
  }

  String _withoutItemPrefix(String message, String itemName) {
    if (!message.startsWith(itemName)) return message;
    final trimmed = message.substring(itemName.length).trimLeft();
    return trimmed.isEmpty ? message : trimmed;
  }

  String _dailyActionLabel(InventoryItem? item, HomeInsight insight) {
    if (item == null) return '记录第一件物品';
    if (insight.itemId != item.id) {
      return item.usageMode == 'manual' ? '记录一次使用' : '看看它';
    }
    return switch (insight.type) {
      'warranty' => '查看期限',
      'stock' => '看看余量',
      'idle' => '安排新去处',
      'ignored' => '重新用起来',
      'positive' => '看看使用记录',
      _ => '看看它',
    };
  }

  Future<void> _handleDailyAction(
    BuildContext context,
    InventoryItem item,
    HomeInsight insight,
  ) async {
    if (insight.itemId == item.id && insight.action == 'recovery') {
      _push(context, const RecoveryScreen());
      return;
    }
    if (insight.itemId != item.id && item.canRecordManualUsage) {
      await runStoreAction(
        context,
        () => AppStore.instance.incrementUsage(item.id, 1),
        successMessage: '已记录一次使用',
      );
      return;
    }
    _openDetail(context, item);
  }

  List<HomeActionItem> _todayActions(
    BuildContext context,
    AppStore store,
    HomeInsight insight,
    InventoryItem? dailyItem,
  ) {
    if (store.items.isEmpty) return const [];
    final actions = <HomeActionItem>[
      if (insight.itemId == null || insight.itemId != dailyItem?.id)
        HomeActionItem(
          label: _insightLabel(insight.type),
          title: insight.title,
          message: insight.message,
          icon: _insightIcon(insight.type),
          color: _insightColor(context),
          onTap: () => _handleInsight(context, insight),
        ),
    ];
    final idleItems = store.items
        .where((item) => item.status == 'idle')
        .toList();
    if (idleItems.isNotEmpty && insight.type != 'idle') {
      actions.add(
        HomeActionItem(
          label: '闲置回看',
          title: '${idleItems.length} 件物品正在等待决定',
          message: '用一次或回血，都比继续放着更有答案。',
          icon: Icons.recycling_rounded,
          color: Theme.of(context).colorScheme.primary,
          onTap: () => _push(context, const RecoveryScreen()),
        ),
      );
    }
    final coolingWishes = store.wishlist
        .where((entry) => entry.status == 'cooling')
        .toList();
    if (coolingWishes.isNotEmpty &&
        insight.type != 'wishlist' &&
        actions.length < 3) {
      coolingWishes.sort(
        (first, second) => first.remainingDays.compareTo(second.remainingDays),
      );
      actions.add(
        HomeActionItem(
          label: '心愿冷静期',
          title: '${coolingWishes.length} 个心愿还在等待答案',
          message: '最近的一个还有 ${coolingWishes.first.remainingDays} 天结束冷静期。',
          icon: Icons.favorite_border_rounded,
          color: Theme.of(context).colorScheme.primary,
          onTap: () => _push(context, const WishlistScreen()),
        ),
      );
    }
    if (actions.length < 2) {
      actions.add(
        HomeActionItem(
          label: '生活整理',
          title: '把常用物品放到顺手的位置',
          message: '打开归处地图，看看家中物品都分布在哪里。',
          icon: Icons.shelves,
          color: Theme.of(context).colorScheme.primary,
          onTap: () => _push(context, const StorageScreen()),
        ),
      );
    }
    return actions.take(3).toList();
  }

  IconData _insightIcon(String type) {
    return switch (type) {
      'warranty' => Icons.event_available_outlined,
      'stock' => Icons.inventory_2_outlined,
      'idle' => Icons.recycling_rounded,
      'wishlist' => Icons.favorite_border_rounded,
      'ignored' => Icons.visibility_off_outlined,
      'positive' => Icons.auto_awesome_rounded,
      _ => Icons.add_circle_outline_rounded,
    };
  }

  String _insightLabel(String type) {
    return switch (type) {
      'warranty' => '期限提醒',
      'stock' => '库存提醒',
      'idle' => '闲置提醒',
      'wishlist' => '心愿提醒',
      'ignored' => '使用提醒',
      'positive' => '今日记录',
      _ => '今日洞察',
    };
  }

  Color _insightColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
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
    MainShell.of(context).openItems();
  }

  Future<void> _openLogin(BuildContext context) async {
    final synced = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const LoginScreen()));
    if (synced == true && context.mounted) {
      MainShell.of(context).selectTab(0);
      showAppSnack(context, '登录成功');
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
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = AppThemeTokens.of(context).softPrimary;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
      child: Row(
        children: [
          Expanded(
            child: IconShortcut(
              icon: Icons.home_work_outlined,
              label: '归处',
              color: primary,
              backgroundColor: softPrimary,
              onTap: onStorage,
            ),
          ),
          Expanded(
            child: IconShortcut(
              icon: Icons.favorite_border_rounded,
              label: '心愿匣',
              color: primary,
              backgroundColor: softPrimary,
              onTap: onWishlist,
            ),
          ),
          Expanded(
            child: IconShortcut(
              icon: Icons.recycling_rounded,
              label: '惜物',
              color: primary,
              backgroundColor: softPrimary,
              onTap: onRecovery,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.guestAddsRemaining, required this.onLogin});

  final int guestAddsRemaining;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: primary.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onLogin,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 10, 9),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_rounded, size: 16, color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guestAddsRemaining == 0
                          ? '本机游客 · 添加次数已用完'
                          : '本机游客 · 还可添加 $guestAddsRemaining 次',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '登录',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: primary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FirstRecordGuide extends StatelessWidget {
  const _FirstRecordGuide();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = AppThemeTokens.of(context).softPrimary;
    const entries = [
      (Icons.photo_camera_outlined, '今天拍下的样子', '照片会成为每次回看的起点'),
      (Icons.timeline_rounded, '一条使用轨迹', '看见它真正参与生活的多少天'),
      (Icons.auto_graph_rounded, '一份日常价值', '把价格换算成每天真实的陪伴'),
    ];
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: softPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(entries[index].$1, size: 18, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entries[index].$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entries[index].$3,
                        style: TextStyle(
                          color: context.appMutedColor,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (index < entries.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
