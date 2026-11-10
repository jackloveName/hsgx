import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sparkleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  late final AnimationController _unlockController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );
  late Set<String> _knownUnlocked;
  _BadgeData? _celebratingBadge;
  int _groupsRevision = -1;
  List<_BadgeGroup>? _groupsCache;

  @override
  void initState() {
    super.initState();
    _knownUnlocked = _unlockedIds();
    AppStore.instance.addListener(_handleStoreChanged);
    _unlockController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _celebratingBadge = null);
      }
    });
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_handleStoreChanged);
    _sparkleController.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  Set<String> _unlockedIds() {
    return _cachedGroups(AppStore.instance)
        .expand((group) => group.badges)
        .where((badge) => badge.unlocked)
        .map((badge) => badge.id)
        .toSet();
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    final current = _unlockedIds();
    final added = current.difference(_knownUnlocked);
    _knownUnlocked = current;
    if (added.isEmpty) return;
    final badge = _cachedGroups(AppStore.instance)
        .expand((group) => group.badges)
        .firstWhere((candidate) => candidate.id == added.first);
    if (MediaQuery.disableAnimationsOf(context)) {
      showAppSnack(context, '点亮新徽章：${badge.name}');
      return;
    }
    setState(() => _celebratingBadge = badge);
    _unlockController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final groups = _cachedGroups(AppStore.instance);
        final allBadges = groups.expand((group) => group.badges).toList();
        final unlocked = allBadges.where((badge) => badge.unlocked).length;
        final locked = allBadges.where((badge) => !badge.unlocked).toList()
          ..sort((a, b) {
            final byProgress = b.progress.compareTo(a.progress);
            if (byProgress != 0) return byProgress;
            return (a.target - a.value).compareTo(b.target - b.value);
          });
        final nextBadge = locked.isEmpty ? null : locked.first;
        final page = PageFrame(
          title: '匣光',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                padding: EdgeInsets.zero,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _StarlightBackdrop(
                          animation: _sparkleController,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          _BadgeBoxProgress(
                            unlocked: unlocked,
                            total: allBadges.length,
                            animation: _sparkleController,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        unlocked > 0
                                            ? '匣中已亮起 $unlocked 枚星光'
                                            : '第一枚星光正等你拾起',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    _TwinklingStar(
                                      key: const Key('top-badge-star'),
                                      animation: _sparkleController,
                                      phase: 0,
                                      color: const Color(0xFFFFDB7D),
                                      size: 19,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '认真记录、好好使用、温柔告别，徽章会自己悄悄出现。',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (nextBadge == null)
                const _AllBadgesUnlockedCard()
              else
                _NextBadgeCard(
                  badge: nextBadge,
                  onTap: () => _showBadgeDetails(nextBadge),
                ),
              for (final group in groups) ...[
                const SizedBox(height: 14),
                _BadgeCabinet(
                  group: group,
                  animation: _sparkleController,
                  onBadgeTap: _showBadgeDetails,
                ),
              ],
            ],
          ),
        );
        return Stack(
          children: [
            page,
            if (_celebratingBadge != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: _UnlockCelebration(
                    badge: _celebratingBadge!,
                    animation: _unlockController,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showBadgeDetails(_BadgeData badge) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _BadgeDetailsSheet(badge: badge),
    );
  }

  List<_BadgeGroup> _cachedGroups(AppStore store) {
    if (_groupsCache == null || _groupsRevision != store.dataRevision) {
      _groupsCache = _buildGroups(store);
      _groupsRevision = store.dataRevision;
    }
    return _groupsCache!;
  }

  List<_BadgeGroup> _buildGroups(AppStore store) {
    final items = store.items;
    final wishlist = store.wishlist;
    final usageCount = items.fold<int>(0, (sum, item) => sum + item.usageDays);
    final highFrequencyCount = items
        .where((item) => item.usageDaysInLastDays(30) >= 8)
        .length;
    final decidedWishes = wishlist
        .where(
          (entry) =>
              const ['wanted', 'abandoned', 'achieved'].contains(entry.status),
        )
        .length;
    final abandonedWishes = wishlist
        .where((entry) => entry.status == 'abandoned')
        .length;
    final achievedWishes = wishlist
        .where((entry) => entry.status == 'achieved')
        .length;
    final avoidedValue = store.avoidedAmount;
    final processedCount = items
        .where((item) => const ['processed', 'retired'].contains(item.status))
        .length;
    final recoveredValue = items
        .where((item) => item.canAggregateInBaseCurrency)
        .fold<double>(0, (sum, item) => sum + item.cashRecoveredAmount);
    final categoryCount = items.map((item) => item.category).toSet().length;
    final contentCount = items
        .where(
          (item) =>
              item.note.trim().isNotEmpty ||
              item.imagePaths.isNotEmpty ||
              item.tags.isNotEmpty,
        )
        .length;
    final taggedCount = items.where((item) => item.tags.isNotEmpty).length;
    final imageCount = items.where((item) => item.imagePaths.isNotEmpty).length;
    final warrantyCount = items
        .where((item) => item.warrantyPeriod.isNotEmpty)
        .length;
    final favoriteCount = items.where((item) => item.favorite).length;
    final idleCount = items.where((item) => item.status == 'idle').length;
    final manualUsageTotal = items
        .where((item) => item.usageMode == 'manual')
        .fold<int>(0, (sum, item) => sum + item.manualUsageCount);
    final autoUsageDays = items
        .where((item) => item.usageMode != 'manual')
        .fold<int>(0, (sum, item) => sum + item.usageDays);
    final relationCount =
        (items.fold<int>(0, (sum, item) => sum + item.relatedItemIds.length) /
                2)
            .round();
    final repairCount = items.fold<int>(
      0,
      (sum, item) =>
          sum +
          item.statusHistory
              .where((entry) => entry.status == 'repairing')
              .length,
    );
    final recycleCount = items
        .where((item) => item.disposalMethod == '回收')
        .length;
    final saleCount = items.where((item) => item.disposalMethod == '转卖').length;
    final noteCount = items.where((item) => item.note.trim().isNotEmpty).length;
    final locatedCount = items
        .where((item) => item.storageLocation.trim().isNotEmpty)
        .length;
    final longestDays = items.fold<int>(
      0,
      (longest, item) => item.ownedDays > longest ? item.ownedDays : longest,
    );

    return [
      _BadgeGroup(
        name: '收藏成长',
        color: const Color(0xFF3A9D8A),
        badges: [
          _badge(
            'first',
            '拾',
            '初次拾取',
            '登记第一件生活物品',
            0xFF3A9D8A,
            items.length,
            1,
          ),
          _badge(
            'collector',
            '匣',
            '十件收藏',
            '收藏十件值得记住的物品',
            0xFF6C9BE2,
            favoriteCount,
            10,
          ),
          _badge(
            'century',
            '满',
            '百件入库',
            '累计登记一百件生活物品',
            0xFF8B78C9,
            items.length,
            100,
          ),
          _badge(
            'explore',
            '探',
            '分类探索',
            '收藏五个不同生活分类',
            0xFFD77FA5,
            categoryCount,
            5,
          ),
          _badge(
            'all-category',
            '全',
            '全品类收藏',
            '覆盖全部生活分类',
            0xFF62AFA0,
            categoryCount,
            itemCategories.length,
          ),
          _badge(
            'favorites',
            '爱',
            '收藏家',
            '收藏二十件物品',
            0xFFE7849A,
            favoriteCount,
            20,
          ),
          _badge(
            'half-century',
            '半',
            '半百入库',
            '累计登记五十件生活物品',
            0xFFC98C4E,
            items.length,
            50,
          ),
          _badge(
            'category-master',
            '类',
            '分类达人',
            '覆盖八个不同生活分类',
            0xFFB96A63,
            categoryCount,
            8,
          ),
        ],
      ),
      _BadgeGroup(
        name: '使用陪伴',
        color: const Color(0xFFD99A45),
        badges: [
          _badge('usage', '用', '使用达人', '累计记录二十次使用', 0xFFDDA64D, usageCount, 20),
          _badge(
            'high-frequency',
            '频',
            '高频陪伴',
            '让一件物品近 30 天高频使用',
            0xFF6C9BE2,
            highFrequencyCount,
            1,
          ),
          _badge(
            'well-used',
            '尽',
            '物尽其用',
            '累计记录一百次使用',
            0xFF3A9D8A,
            usageCount,
            100,
          ),
          _badge(
            'companion',
            '伴',
            '长期陪伴',
            '拥有一件超过一年的物品',
            0xFF62AFA0,
            longestDays,
            365,
          ),
          _badge(
            'three-year',
            '久',
            '三年之约',
            '持有一件物品超过三年',
            0xFF8B78C9,
            longestDays,
            1095,
          ),
          _badge(
            'manual-50',
            '记',
            '手动记录达人',
            '手动累计记录五十次使用',
            0xFFD99A45,
            manualUsageTotal,
            50,
          ),
          _badge(
            'manual-200',
            '勤',
            '使用记录家',
            '手动累计记录两百次使用',
            0xFFC97C68,
            manualUsageTotal,
            200,
          ),
          _badge(
            'auto-1000',
            '久',
            '千日陪伴',
            '自动使用天数累计一千天',
            0xFF4AAE9C,
            autoUsageDays,
            1000,
          ),
          _badge(
            'related-usage',
            '联',
            '组合使用家',
            '关联五组互相关联的物品',
            0xFF6C9FE8,
            relationCount,
            5,
          ),
        ],
      ),
      _BadgeGroup(
        name: '理性选择',
        color: const Color(0xFF8B78C9),
        badges: [
          _badge(
            'wish',
            '愿',
            '理性心愿',
            '认真完成一次心愿决策',
            0xFF8B78C9,
            decidedWishes,
            1,
          ),
          _badge(
            'avoid',
            '舍',
            '理性取舍',
            '放下一件不再需要的心愿',
            0xFFE7849A,
            abandonedWishes,
            1,
          ),
          _badge(
            'decisions',
            '定',
            '冷静达人',
            '完成五次心愿决策',
            0xFF6C9FE8,
            decidedWishes,
            5,
          ),
          _badge(
            'saving',
            '省',
            '节省达人',
            '通过放弃心愿避免一千元支出',
            0xFFDDA64D,
            avoidedValue,
            1000,
          ),
          _badge(
            'wishlist',
            '整',
            '心愿整理师',
            '累计记录十个心愿',
            0xFFD77FA5,
            wishlist.length,
            10,
          ),
          _badge(
            'decisions-ten',
            '断',
            '果断十次',
            '完成十次心愿决策',
            0xFF786BC2,
            decidedWishes,
            10,
          ),
          _badge(
            'achieved-five',
            '成',
            '心愿达成家',
            '让五个心愿真正实现',
            0xFF43AFC6,
            achievedWishes,
            5,
          ),
          _badge(
            'saving-5000',
            '省',
            '五千守门员',
            '通过放弃心愿避免五千元支出',
            0xFFD5A13D,
            avoidedValue,
            5000,
          ),
          _badge(
            'abandoned-twenty',
            '舍',
            '清醒舍弃',
            '认真放弃二十个不再需要的心愿',
            0xFFE7849A,
            abandonedWishes,
            20,
          ),
        ],
      ),
      _BadgeGroup(
        name: '生命周期',
        color: const Color(0xFF6C9FE8),
        badges: [
          _badge(
            'recovery',
            '回',
            '回血行动',
            '完成一次闲置物品处理',
            0xFFE4B15C,
            processedCount,
            1,
          ),
          _badge(
            'recovery-master',
            '转',
            '回血达人',
            '完成五次物品处理',
            0xFF6C9BE2,
            processedCount,
            5,
          ),
          _badge(
            'recovery-value',
            '金',
            '万元回血',
            '累计回血金额达到一万元',
            0xFFDDA64D,
            recoveredValue,
            10000,
          ),
          _badge(
            'idle-clear',
            '清',
            '闲置清零',
            '有物品时保持没有长期闲置',
            0xFF3A9D8A,
            items.isNotEmpty && idleCount == 0 ? 1 : 0,
            1,
          ),
          _badge(
            'idle-first',
            '闲',
            '第一次冷静',
            '第一次把物品切换为闲置状态',
            0xFFD99A45,
            items
                .where(
                  (item) =>
                      item.statusHistory.any((entry) => entry.status == 'idle'),
                )
                .length,
            1,
          ),
          _badge(
            'repair-first',
            '修',
            '首次送修',
            '第一次进入维修状态',
            0xFFE88778,
            repairCount,
            1,
          ),
          _badge(
            'repair-master',
            '匠',
            '维修观察员',
            '累计记录三次维修',
            0xFFB56D9C,
            repairCount,
            3,
          ),
          _badge(
            'recycle-five',
            '循',
            '循环守护者',
            '完成五次物品回收',
            0xFF4AAE9C,
            recycleCount,
            5,
          ),
          _badge(
            'sale-five',
            '售',
            '转卖小能手',
            '完成五次物品转卖',
            0xFF6C9FE8,
            saleCount,
            5,
          ),
          _badge(
            'value-50000',
            '金',
            '五万回血家',
            '累计回血金额达到五万元',
            0xFFDDA64D,
            recoveredValue,
            50000,
          ),
        ],
      ),
      _BadgeGroup(
        name: '生活记录',
        color: const Color(0xFFD77FA5),
        badges: [
          _badge(
            'content',
            '录',
            '生活记录者',
            '为五件物品补充照片、备注或标签',
            0xFF6C9FE8,
            contentCount,
            5,
          ),
          _badge('tags', '签', '标签达人', '为五件物品添加标签', 0xFF8B78C9, taggedCount, 5),
          _badge(
            'images',
            '影',
            '图文收藏家',
            '为十件物品保存照片',
            0xFFD77FA5,
            imageCount,
            10,
          ),
          _badge(
            'warranty',
            '保',
            '保修守护',
            '记录五件物品的保修信息',
            0xFF62AFA0,
            warrantyCount,
            5,
          ),
          _badge(
            'notes-ten',
            '文',
            '备注整理师',
            '为十件物品写下备注',
            0xFFC97C68,
            noteCount,
            10,
          ),
          _badge(
            'tags-twenty',
            '签',
            '标签收藏家',
            '为二十件物品添加标签',
            0xFF8B78C9,
            taggedCount,
            20,
          ),
          _badge(
            'images-fifty',
            '影',
            '影像档案家',
            '为五十件物品保存照片',
            0xFFD77FA5,
            imageCount,
            50,
          ),
          _badge(
            'located-ten',
            '位',
            '收纳规划师',
            '为十件物品设置收纳位置',
            0xFF4B9F91,
            locatedCount,
            10,
          ),
        ],
      ),
    ];
  }

  _BadgeData _badge(
    String id,
    String glyph,
    String name,
    String description,
    int colorValue,
    num value,
    num target,
  ) {
    return _BadgeData(
      id: id,
      glyph: glyph,
      name: name,
      description: description,
      color: Color(colorValue),
      value: value.toDouble(),
      target: target.toDouble(),
    );
  }
}

class _BadgeGroup {
  const _BadgeGroup({
    required this.name,
    required this.color,
    required this.badges,
  });

  final String name;
  final Color color;
  final List<_BadgeData> badges;

  int get unlocked => badges.where((badge) => badge.unlocked).length;
}

enum _BadgeShape {
  rosette,
  shield,
  hexagon,
  stamp,
  crown,
  compass,
  heart,
  book,
  ticket,
  gear,
  leaf,
  coin,
  trophy,
  chest,
  stack,
  clock,
  flame,
  arch,
}

class _BadgeData {
  const _BadgeData({
    required this.id,
    required this.glyph,
    required this.name,
    required this.description,
    required this.color,
    required this.value,
    required this.target,
  });

  final String id;
  final String glyph;
  final String name;
  final String description;
  final Color color;
  final double value;
  final double target;

  _BadgeShape get shape => switch (id) {
    'first' => _BadgeShape.chest,
    'collector' => _BadgeShape.stack,
    'century' => _BadgeShape.crown,
    'explore' => _BadgeShape.compass,
    'all-category' => _BadgeShape.rosette,
    'favorites' => _BadgeShape.heart,
    'half-century' => _BadgeShape.arch,
    'category-master' => _BadgeShape.shield,
    'usage' => _BadgeShape.clock,
    'high-frequency' => _BadgeShape.flame,
    'well-used' => _BadgeShape.leaf,
    'companion' => _BadgeShape.heart,
    'three-year' => _BadgeShape.arch,
    'manual-50' => _BadgeShape.book,
    'manual-200' => _BadgeShape.book,
    'auto-1000' => _BadgeShape.clock,
    'related-usage' => _BadgeShape.hexagon,
    'wish' => _BadgeShape.ticket,
    'avoid' => _BadgeShape.shield,
    'decisions' => _BadgeShape.rosette,
    'saving' => _BadgeShape.coin,
    'wishlist' => _BadgeShape.ticket,
    'decisions-ten' => _BadgeShape.hexagon,
    'achieved-five' => _BadgeShape.trophy,
    'saving-5000' => _BadgeShape.coin,
    'abandoned-twenty' => _BadgeShape.shield,
    'recovery' => _BadgeShape.hexagon,
    'recovery-master' => _BadgeShape.gear,
    'recovery-value' => _BadgeShape.coin,
    'idle-clear' => _BadgeShape.leaf,
    'idle-first' => _BadgeShape.clock,
    'repair-first' => _BadgeShape.gear,
    'repair-master' => _BadgeShape.gear,
    'recycle-five' => _BadgeShape.leaf,
    'sale-five' => _BadgeShape.ticket,
    'value-50000' => _BadgeShape.coin,
    'content' => _BadgeShape.book,
    'tags' => _BadgeShape.ticket,
    'images' => _BadgeShape.stamp,
    'warranty' => _BadgeShape.shield,
    'notes-ten' => _BadgeShape.book,
    'tags-twenty' => _BadgeShape.ticket,
    'images-fifty' => _BadgeShape.stamp,
    'located-ten' => _BadgeShape.arch,
    _ => _BadgeShape.rosette,
  };

  IconData get icon => switch (id) {
    'first' => Icons.inventory_2_outlined,
    'collector' => Icons.collections_bookmark_outlined,
    'century' => Icons.workspace_premium_outlined,
    'explore' => Icons.explore_outlined,
    'all-category' => Icons.category_outlined,
    'favorites' => Icons.favorite_rounded,
    'half-century' => Icons.military_tech_outlined,
    'category-master' => Icons.dashboard_customize_outlined,
    'usage' => Icons.touch_app_outlined,
    'high-frequency' => Icons.local_fire_department_outlined,
    'well-used' => Icons.auto_awesome_rounded,
    'companion' => Icons.handshake_outlined,
    'three-year' => Icons.history_toggle_off_rounded,
    'manual-50' => Icons.edit_note_rounded,
    'manual-200' => Icons.rate_review_outlined,
    'auto-1000' => Icons.timelapse_rounded,
    'related-usage' => Icons.hub_outlined,
    'wish' => Icons.checklist_rounded,
    'avoid' => Icons.savings_outlined,
    'decisions' => Icons.task_alt_rounded,
    'saving' => Icons.savings_rounded,
    'wishlist' => Icons.favorite_border_rounded,
    'decisions-ten' => Icons.rule_rounded,
    'achieved-five' => Icons.emoji_events_outlined,
    'saving-5000' => Icons.shield_outlined,
    'abandoned-twenty' => Icons.block_rounded,
    'recovery' => Icons.recycling_rounded,
    'recovery-master' => Icons.currency_exchange_rounded,
    'recovery-value' => Icons.paid_outlined,
    'idle-clear' => Icons.cleaning_services_outlined,
    'idle-first' => Icons.pause_circle_outline_rounded,
    'repair-first' => Icons.build_outlined,
    'repair-master' => Icons.handyman_outlined,
    'recycle-five' => Icons.eco_outlined,
    'sale-five' => Icons.sell_outlined,
    'value-50000' => Icons.account_balance_wallet_outlined,
    'content' => Icons.post_add_rounded,
    'tags' => Icons.label_outline_rounded,
    'images' => Icons.photo_library_outlined,
    'warranty' => Icons.verified_user_outlined,
    'notes-ten' => Icons.edit_note_rounded,
    'tags-twenty' => Icons.label_rounded,
    'images-fifty' => Icons.collections_rounded,
    'located-ten' => Icons.shelves,
    _ => Icons.workspace_premium_outlined,
  };

  bool get unlocked => value >= target;
  double get progress => target <= 0 ? 0 : (value / target).clamp(0, 1);
  String get progressText => value >= target
      ? '100%'
      : '${value.round().clamp(0, target.round())}/${target.round()}';
}

class _BadgeBoxProgress extends StatelessWidget {
  const _BadgeBoxProgress({
    required this.unlocked,
    required this.total,
    required this.animation,
  });

  final int unlocked;
  final int total;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : unlocked / total;
    return Semantics(
      label: '已点亮 $unlocked / $total',
      child: SizedBox(
        key: const Key('badge-box-progress'),
        width: 82,
        height: 82,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => CustomPaint(
            painter: _BadgeBoxPainter(
              progress: progress,
              sparkle: MediaQuery.disableAnimationsOf(context)
                  ? 0.35
                  : animation.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeBoxPainter extends CustomPainter {
  const _BadgeBoxPainter({required this.progress, required this.sparkle});

  final double progress;
  final double sparkle;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 82;
    final scaleY = size.height / 82;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    final pulse = (math.sin(sparkle * math.pi * 2) + 1) / 2;
    final auraRect = Rect.fromCircle(
      center: const Offset(41, 38),
      radius: 36 + pulse * 3,
    );
    canvas.drawCircle(
      auraRect.center,
      auraRect.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE49A).withValues(alpha: 0.2 + pulse * 0.08),
            const Color(0xFF72E2CF).withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(auraRect),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(41, 73), width: 48, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    final body = Path()
      ..moveTo(18, 32)
      ..lineTo(64, 32)
      ..lineTo(71, 71)
      ..lineTo(11, 71)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x3369E4D2), Color(0x22FFD873)],
        ).createShader(body.getBounds()),
    );
    canvas.save();
    canvas.clipPath(body);
    if (progress > 0) {
      final fillTop = (71 - 39 * progress.clamp(0, 1)).toDouble();
      final fill = Rect.fromLTRB(10, fillTop, 72, 72);
      canvas.drawRect(
        fill,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x99FFF0B0), Color(0xFFFFC95F)],
          ).createShader(fill),
      );
    }
    final shineRect = Rect.fromLTWH(-25 + sparkle * 90, 32, 11, 40);
    canvas.drawRect(
      shineRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(shineRect),
    );
    canvas.restore();
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xFFFFE7A3).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawLine(
      const Offset(41, 33),
      const Offset(41, 70),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 1.2,
    );

    canvas.save();
    canvas.translate(41, 24);
    canvas.rotate((pulse - 0.5) * 0.05);
    canvas.translate(-41, -24 - pulse * 2);
    final lid = Path()
      ..moveTo(9, 28)
      ..lineTo(41, 13)
      ..lineTo(73, 28)
      ..lineTo(64, 37)
      ..lineTo(41, 29)
      ..lineTo(18, 37)
      ..close();
    canvas.drawPath(
      lid,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x55FFF1B7), Color(0x225CE1CF)],
        ).createShader(lid.getBounds()),
    );
    canvas.drawPath(
      lid,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.76)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    final gem = Path()
      ..moveTo(41, 43)
      ..lineTo(46, 51)
      ..lineTo(41, 60)
      ..lineTo(36, 51)
      ..close();
    canvas.drawPath(
      gem,
      Paint()
        ..color = const Color(0xFFFFF2BD).withValues(alpha: 0.45 + pulse * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawPath(
      gem,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (var index = 0; index < 5; index++) {
      final phase = (sparkle + index * 0.19) % 1;
      final x = 27.0 + index * 7;
      final y = 30 - phase * 18;
      final opacity = (1 - phase) * 0.72;
      final sparklePaint = Paint()
        ..color = const Color(0xFFFFECB2).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), index.isEven ? 1.4 : 0.9, sparklePaint);
      if (index.isEven) {
        canvas.drawLine(
          Offset(x - 2.6, y),
          Offset(x + 2.6, y),
          sparklePaint..strokeWidth = 0.7,
        );
        canvas.drawLine(Offset(x, y - 2.6), Offset(x, y + 2.6), sparklePaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BadgeBoxPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.sparkle != sparkle;
  }
}

class _BadgeMedal extends StatelessWidget {
  const _BadgeMedal({
    super.key,
    required this.color,
    required this.unlocked,
    required this.icon,
    required this.glyph,
    required this.shape,
    this.size = 58,
  });

  final Color color;
  final bool unlocked;
  final IconData icon;
  final String glyph;
  final _BadgeShape shape;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = unlocked ? color : const Color(0xFFAAA49C);
    return Semantics(
      image: true,
      label: '徽章 $glyph',
      child: SizedBox.square(
        dimension: size,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BadgeMedalPainter(
                      color: tone,
                      unlocked: unlocked,
                      shape: shape,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 12,
                  child: Icon(
                    icon,
                    size: 18,
                    color: unlocked ? color : const Color(0xFF9F9991),
                  ),
                ),
                Positioned(
                  left: 22,
                  bottom: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: unlocked
                          ? tone.withValues(alpha: 0.9)
                          : const Color(0xFFC7C1B9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      glyph,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeMedalPainter extends CustomPainter {
  const _BadgeMedalPainter({
    required this.color,
    required this.unlocked,
    required this.shape,
  });

  final Color color;
  final bool unlocked;
  final _BadgeShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 58, size.height / 58);
    final center = const Offset(29, 25);

    if (_hasRibbon(shape)) {
      final leftRibbon = Path()
        ..moveTo(20, 29)
        ..lineTo(28, 36)
        ..lineTo(23, 57)
        ..lineTo(14, 50)
        ..lineTo(12, 37)
        ..close();
      final rightRibbon = Path()
        ..moveTo(38, 29)
        ..lineTo(30, 36)
        ..lineTo(35, 57)
        ..lineTo(44, 50)
        ..lineTo(46, 37)
        ..close();
      final ribbonPaint = Paint()
        ..color = color.withValues(alpha: unlocked ? 0.52 : 0.2);
      canvas.drawPath(leftRibbon, ribbonPaint);
      canvas.drawPath(rightRibbon, ribbonPaint);
    }

    final medalObject = _medalPath(shape, center);
    final medalRect = medalObject.getBounds();
    canvas.drawPath(
      medalObject,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [
            Colors.white.withValues(alpha: unlocked ? 0.99 : 0.92),
            Color.lerp(Colors.white, color, unlocked ? 0.4 : 0.14)!,
          ],
        ).createShader(medalRect),
    );
    canvas.drawPath(
      medalObject,
      Paint()
        ..color = color.withValues(alpha: unlocked ? 0.92 : 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );

    _paintShapeDetails(canvas, shape, color, center);

    canvas.drawCircle(
      center,
      shape == _BadgeShape.stamp || shape == _BadgeShape.book ? 12.5 : 13.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.72)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      shape == _BadgeShape.stamp || shape == _BadgeShape.book ? 12.5 : 13.5,
      Paint()
        ..color = color.withValues(alpha: unlocked ? 0.5 : 0.24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BadgeMedalPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.unlocked != unlocked ||
        oldDelegate.shape != shape;
  }
}

bool _hasRibbon(_BadgeShape shape) {
  return switch (shape) {
    _BadgeShape.rosette ||
    _BadgeShape.shield ||
    _BadgeShape.hexagon ||
    _BadgeShape.coin ||
    _BadgeShape.trophy ||
    _BadgeShape.arch => true,
    _ => false,
  };
}

Path _medalPath(_BadgeShape shape, Offset center) {
  final path = Path();
  switch (shape) {
    case _BadgeShape.rosette:
      const points = 24;
      for (var index = 0; index < points; index++) {
        final angle = -math.pi / 2 + index * math.pi * 2 / points;
        final radius = index.isEven ? 22.0 : 19.2;
        final point = center.translate(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        );
        index == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      path.close();
    case _BadgeShape.shield:
      path
        ..moveTo(10, 7)
        ..lineTo(48, 7)
        ..lineTo(47, 27)
        ..quadraticBezierTo(45, 39, 29, 49)
        ..quadraticBezierTo(13, 39, 11, 27)
        ..close();
    case _BadgeShape.hexagon:
      path
        ..moveTo(29, 5)
        ..lineTo(48, 15)
        ..lineTo(48, 35)
        ..lineTo(29, 46)
        ..lineTo(10, 35)
        ..lineTo(10, 15)
        ..close();
    case _BadgeShape.stamp:
      path.addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(8, 6, 42, 39),
          const Radius.circular(5),
        ),
      );
    case _BadgeShape.crown:
      path
        ..moveTo(8, 17)
        ..lineTo(18, 25)
        ..lineTo(29, 7)
        ..lineTo(40, 25)
        ..lineTo(50, 17)
        ..lineTo(46, 42)
        ..lineTo(12, 42)
        ..close();
    case _BadgeShape.compass:
      for (var index = 0; index < 16; index++) {
        final angle = -math.pi / 2 + index * math.pi * 2 / 16;
        final radius = index.isEven ? 22.0 : 14.0;
        final point = center.translate(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        );
        index == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      path.close();
    case _BadgeShape.heart:
      path
        ..moveTo(29, 45)
        ..cubicTo(23, 38, 8, 29, 8, 18)
        ..cubicTo(8, 8, 21, 6, 29, 16)
        ..cubicTo(37, 6, 50, 8, 50, 18)
        ..cubicTo(50, 29, 35, 38, 29, 45)
        ..close();
    case _BadgeShape.book:
      path.addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(10, 7, 38, 38),
          const Radius.circular(7),
        ),
      );
    case _BadgeShape.ticket:
      path.addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 10, 44, 34),
          const Radius.circular(10),
        ),
      );
    case _BadgeShape.gear:
      for (var index = 0; index < 24; index++) {
        final angle = -math.pi / 2 + index * math.pi * 2 / 24;
        final radius = index.isEven ? 22.0 : 17.0;
        final point = center.translate(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        );
        index == 0
            ? path.moveTo(point.dx, point.dy)
            : path.lineTo(point.dx, point.dy);
      }
      path.close();
    case _BadgeShape.leaf:
      path
        ..moveTo(29, 48)
        ..cubicTo(16, 42, 7, 31, 11, 11)
        ..cubicTo(27, 11, 43, 20, 49, 37)
        ..cubicTo(43, 46, 35, 49, 29, 48)
        ..close();
    case _BadgeShape.coin:
      path.addOval(Rect.fromCircle(center: center, radius: 22));
    case _BadgeShape.trophy:
      path
        ..moveTo(14, 6)
        ..lineTo(44, 6)
        ..lineTo(42, 25)
        ..quadraticBezierTo(38, 35, 29, 36)
        ..quadraticBezierTo(20, 35, 16, 25)
        ..close();
    case _BadgeShape.chest:
      path
        ..moveTo(9, 13)
        ..lineTo(29, 5)
        ..lineTo(49, 13)
        ..lineTo(47, 42)
        ..lineTo(11, 42)
        ..close();
    case _BadgeShape.stack:
      path.addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 10, 40, 33),
          const Radius.circular(8),
        ),
      );
    case _BadgeShape.clock:
      path.addOval(Rect.fromCircle(center: center, radius: 22));
    case _BadgeShape.flame:
      path
        ..moveTo(29, 5)
        ..cubicTo(36, 16, 45, 20, 42, 32)
        ..cubicTo(40, 42, 34, 46, 29, 47)
        ..cubicTo(20, 46, 13, 39, 15, 28)
        ..cubicTo(18, 19, 26, 17, 29, 5)
        ..close();
    case _BadgeShape.arch:
      path
        ..moveTo(12, 42)
        ..lineTo(12, 21)
        ..quadraticBezierTo(12, 6, 29, 6)
        ..quadraticBezierTo(46, 6, 46, 21)
        ..lineTo(46, 42)
        ..close();
  }
  return path;
}

void _paintShapeDetails(
  Canvas canvas,
  _BadgeShape shape,
  Color color,
  Offset center,
) {
  final detailPaint = Paint()
    ..color = color.withValues(alpha: 0.32)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.9
    ..strokeCap = StrokeCap.round;
  switch (shape) {
    case _BadgeShape.stamp:
      for (var x = 14.0; x <= 44; x += 6) {
        canvas.drawCircle(Offset(x, 8), 1, detailPaint);
        canvas.drawCircle(Offset(x, 43), 1, detailPaint);
      }
    case _BadgeShape.book:
      canvas.drawLine(const Offset(29, 9), const Offset(29, 43), detailPaint);
    case _BadgeShape.crown:
      for (final x in [18.0, 29.0, 40.0]) {
        canvas.drawCircle(Offset(x, 16), 1.4, detailPaint);
      }
    case _BadgeShape.compass:
      canvas.drawLine(const Offset(29, 9), const Offset(29, 41), detailPaint);
      canvas.drawLine(const Offset(13, 25), const Offset(45, 25), detailPaint);
    case _BadgeShape.trophy:
      canvas.drawLine(const Offset(24, 36), const Offset(24, 46), detailPaint);
      canvas.drawLine(const Offset(34, 36), const Offset(34, 46), detailPaint);
      canvas.drawLine(const Offset(19, 46), const Offset(39, 46), detailPaint);
    case _BadgeShape.chest:
      canvas.drawLine(const Offset(11, 20), const Offset(47, 20), detailPaint);
    case _BadgeShape.stack:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 15, 30, 23),
          const Radius.circular(5),
        ),
        detailPaint,
      );
    case _BadgeShape.clock:
      canvas.drawLine(center, center.translate(0, -11), detailPaint);
      canvas.drawLine(center, center.translate(8, 3), detailPaint);
    case _BadgeShape.flame:
      canvas.drawPath(
        Path()
          ..moveTo(29, 16)
          ..quadraticBezierTo(35, 25, 31, 34),
        detailPaint,
      );
    case _BadgeShape.leaf:
      canvas.drawLine(const Offset(23, 15), const Offset(35, 39), detailPaint);
    case _BadgeShape.heart ||
        _BadgeShape.rosette ||
        _BadgeShape.shield ||
        _BadgeShape.hexagon ||
        _BadgeShape.ticket ||
        _BadgeShape.gear ||
        _BadgeShape.coin ||
        _BadgeShape.arch:
      break;
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.onTap});

  final _BadgeData badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = badge.unlocked ? badge.color : const Color(0xFFB4AEA7);
    return SoftCard(
      key: Key('badge-card-${badge.id}'),
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
      radius: 19,
      color: badge.unlocked
          ? Color.lerp(Colors.white, badge.color, 0.055)!
          : Colors.white,
      borderColor: badge.unlocked
          ? badge.color.withValues(alpha: 0.24)
          : appBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: _BadgeMedal(
              key: Key('badge-medal-${badge.id}'),
              color: badge.color,
              unlocked: badge.unlocked,
              icon: badge.icon,
              glyph: badge.glyph,
              shape: badge.shape,
              size: 64,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(7, 4, 7, 4),
            decoration: BoxDecoration(
              color: badge.unlocked
                  ? badge.color.withValues(alpha: 0.055)
                  : const Color(0xFFF7F4EF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE8E2D9),
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  badge.progressText,
                  key: Key('badge-progress-${badge.id}'),
                  style: TextStyle(
                    color: badge.unlocked ? badge.color : appMuted,
                    fontSize: 8,
                    fontWeight: badge.unlocked
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCabinet extends StatelessWidget {
  const _BadgeCabinet({
    required this.group,
    required this.animation,
    required this.onBadgeTap,
  });

  final _BadgeGroup group;
  final Animation<double> animation;
  final ValueChanged<_BadgeData> onBadgeTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = Color.lerp(scheme.primary, const Color(0xFF172A24), 0.58)!;
    final end = Color.lerp(scheme.secondary, const Color(0xFF1A2828), 0.68)!;
    final hasEmptySlot = group.badges.length.isOdd;
    return Container(
      key: Key('badge-cabinet-${group.name}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: group.color.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: start.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: _CabinetStarMap(animation: animation, color: group.color),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 15, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: group.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Songti SC',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        '${group.unlocked}/${group.badges.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 156,
                  ),
                  itemCount: group.badges.length + (hasEmptySlot ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= group.badges.length) {
                      return const _EmptyCabinetSlot();
                    }
                    final badge = group.badges[index];
                    return _BadgeCard(
                      badge: badge,
                      onTap: () => onBadgeTap(badge),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCabinetSlot extends StatelessWidget {
  const _EmptyCabinetSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_border_rounded,
              color: Colors.white.withValues(alpha: 0.22),
              size: 28,
            ),
            const SizedBox(height: 7),
            Text(
              '下一枚星光',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CabinetStarMap extends StatelessWidget {
  const _CabinetStarMap({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return CustomPaint(
        painter: _CabinetStarMapPainter(progress: 0.35, color: color),
      );
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => CustomPaint(
        painter: _CabinetStarMapPainter(
          progress: animation.value,
          color: color,
        ),
      ),
    );
  }
}

class _CabinetStarMapPainter extends CustomPainter {
  const _CabinetStarMapPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = [
      Offset(size.width * 0.1, size.height * 0.14),
      Offset(size.width * 0.36, size.height * 0.08),
      Offset(size.width * 0.6, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.09),
      Offset(size.width * 0.94, size.height * 0.3),
    ];
    final path = Path()..moveTo(nodes.first.dx, nodes.first.dy);
    for (final node in nodes.skip(1)) {
      path.lineTo(node.dx, node.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    for (var index = 0; index < nodes.length; index++) {
      final pulse = (math.sin((progress + index * 0.17) * math.pi * 2) + 1) / 2;
      final node = nodes[index];
      final paint = Paint()
        ..color = Color.lerp(
          color,
          const Color(0xFFFFE59A),
          0.45,
        )!.withValues(alpha: 0.18 + pulse * 0.42);
      canvas.drawCircle(node, index == 0 ? 2.1 : 1.4, paint);
      if (index == 0) {
        canvas.drawLine(
          node.translate(-5, 0),
          node.translate(5, 0),
          paint..strokeWidth = 0.8,
        );
        canvas.drawLine(node.translate(0, -5), node.translate(0, 5), paint);
      }
    }

    final shelfPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 0.8;
    for (var y = 54.0; y < size.height; y += 174) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), shelfPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CabinetStarMapPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _NextBadgeCard extends StatelessWidget {
  const _NextBadgeCard({required this.badge, required this.onTap});

  final _BadgeData badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      key: const Key('next-badge-card'),
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      color: Color.lerp(Colors.white, badge.color, 0.075)!,
      borderColor: badge.color.withValues(alpha: 0.25),
      radius: 21,
      child: Row(
        children: [
          _BadgeMedal(
            color: badge.color,
            unlocked: badge.unlocked,
            icon: badge.icon,
            glyph: badge.glyph,
            shape: badge.shape,
            size: 76,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '下一枚即将点亮',
                  style: TextStyle(
                    color: badge.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  badge.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: appMuted, fontSize: 9),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: badge.progress,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE9E4DC),
                          color: badge.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(badge.progress * 100).round()}%',
                      style: TextStyle(
                        color: badge.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: appMuted, size: 19),
        ],
      ),
    );
  }
}

class _AllBadgesUnlockedCard extends StatelessWidget {
  const _AllBadgesUnlockedCard();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SoftCard(
      color: Color.lerp(Colors.white, primary, 0.07)!,
      borderColor: primary.withValues(alpha: 0.24),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: primary, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '所有徽章都已点亮',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  '这座收藏匣已经装满了生活的星光。',
                  style: TextStyle(color: appMuted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeDetailsSheet extends StatelessWidget {
  const _BadgeDetailsSheet({required this.badge});

  final _BadgeData badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE1DCD5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            _BadgeMedal(
              color: badge.color,
              unlocked: badge.unlocked,
              icon: badge.icon,
              glyph: badge.glyph,
              shape: badge.shape,
              size: 100,
            ),
            const SizedBox(height: 12),
            Text(
              badge.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: appMuted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: badge.progress,
                minHeight: 7,
                backgroundColor: const Color(0xFFF1EEE9),
                color: badge.color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '完成度',
                  style: TextStyle(
                    color: badge.unlocked ? badge.color : appMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  badge.progressText,
                  style: TextStyle(
                    color: badge.unlocked ? badge.color : appMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockCelebration extends StatelessWidget {
  const _UnlockCelebration({required this.badge, required this.animation});

  final _BadgeData badge;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;
        final fade = progress < 0.74
            ? 1.0
            : ((1 - progress) / 0.26).clamp(0.0, 1.0);
        final scale = Tween<double>(begin: 0.58, end: 1)
            .chain(CurveTween(curve: Curves.elasticOut))
            .transform(progress.clamp(0.03, 1));
        return ColoredBox(
          key: const Key('badge-unlock-celebration'),
          color: Colors.black.withValues(alpha: 0.12 * fade),
          child: Center(
            child: Opacity(
              opacity: fade,
              child: SizedBox(
                width: 260,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _UnlockBurstPainter(
                          progress: progress,
                          color: badge.color,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: scale,
                      child: _BadgeMedal(
                        color: badge.color,
                        unlocked: true,
                        icon: badge.icon,
                        glyph: badge.glyph,
                        shape: badge.shape,
                        size: 112,
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: badge.color.withValues(alpha: 0.2),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '新徽章点亮',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              badge.name,
                              style: TextStyle(
                                color: badge.color,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UnlockBurstPainter extends CustomPainter {
  const _UnlockBurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(progress.clamp(0, 1));
    final ringPaint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, 34 + eased * 72, ringPaint);
    canvas.drawCircle(
      center,
      26 + eased * 48,
      ringPaint..color = color.withValues(alpha: (1 - progress) * 0.2),
    );

    for (var index = 0; index < 18; index++) {
      final angle = math.pi * 2 * index / 18 + progress * 0.35;
      final distance = 38 + eased * (58 + (index % 4) * 9);
      final start = center.translate(
        math.cos(angle) * distance * 0.72,
        math.sin(angle) * distance * 0.72,
      );
      final end = center.translate(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color.withValues(alpha: (1 - progress) * 0.72)
          ..strokeWidth = index.isEven ? 1.5 : 0.9
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        end,
        index.isEven ? 2.1 : 1.2,
        Paint()
          ..color = const Color(0xFFFFE69A).withValues(alpha: 1 - progress),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UnlockBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _TwinklingStar extends StatelessWidget {
  const _TwinklingStar({
    super.key,
    required this.animation,
    required this.phase,
    required this.color,
    this.size = 13,
  });

  final Animation<double> animation;
  final double phase;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return Icon(Icons.star_rounded, size: size, color: color);
    }
    return SizedBox(
      width: size * 2.1,
      height: size * 2.1,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final progress = (animation.value + phase) % 1;
            final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;
            final angle = (pulse - 0.5) * 0.32;
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 0.88 + pulse * 0.12,
                  child: Container(
                    width: size * 1.8,
                    height: size * 1.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.28 + pulse * 0.12),
                          color.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size.square(size * 1.55),
                  painter: _StarRaysPainter(pulse: pulse, color: color),
                ),
                Opacity(
                  opacity: 0.68 + pulse * 0.32,
                  child: Transform.rotate(
                    angle: angle,
                    child: Transform.scale(
                      scale: 0.84 + pulse * 0.22,
                      child: Icon(
                        Icons.star_rounded,
                        size: size,
                        color: color,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.62),
                            blurRadius: 9,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StarRaysPainter extends CustomPainter {
  const _StarRaysPainter({required this.pulse, required this.color});

  final double pulse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.18 + pulse * 0.3)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
    final diagonal = radius * 0.58;
    paint.color = color.withValues(alpha: 0.08 + pulse * 0.14);
    canvas.drawLine(
      Offset(center.dx - diagonal, center.dy - diagonal),
      Offset(center.dx + diagonal, center.dy + diagonal),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + diagonal, center.dy - diagonal),
      Offset(center.dx - diagonal, center.dy + diagonal),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StarRaysPainter oldDelegate) {
    return oldDelegate.pulse != pulse || oldDelegate.color != color;
  }
}

class _StarlightBackdrop extends StatelessWidget {
  const _StarlightBackdrop({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) =>
          CustomPaint(painter: _StarlightPainter(progress: animation.value)),
    );
  }
}

class _StarlightPainter extends CustomPainter {
  const _StarlightPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final glowRect = Rect.fromCircle(
      center: Offset(size.width * 0.84, size.height * 0.16),
      radius: size.height * 0.48,
    );
    canvas.drawCircle(
      glowRect.center,
      glowRect.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE7A3).withValues(alpha: 0.16),
            const Color(0xFFFFE7A3).withValues(alpha: 0.03),
            Colors.transparent,
          ],
        ).createShader(glowRect),
    );

    final orbit = Path()
      ..moveTo(size.width * 0.53, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.02,
        size.width * 0.83,
        size.height * 0.25,
      )
      ..quadraticBezierTo(
        size.width * 0.93,
        size.height * 0.42,
        size.width * 0.96,
        size.height * 0.18,
      );
    canvas.drawPath(
      orbit,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    final points = <({double x, double y, double phase, double radius})>[
      (x: 0.55, y: 0.2, phase: 0.05, radius: 1.6),
      (x: 0.64, y: 0.11, phase: 0.38, radius: 1.1),
      (x: 0.72, y: 0.28, phase: 0.71, radius: 1.4),
      (x: 0.82, y: 0.13, phase: 0.19, radius: 1.8),
      (x: 0.9, y: 0.3, phase: 0.56, radius: 1.0),
      (x: 0.96, y: 0.12, phase: 0.83, radius: 1.2),
      (x: 0.47, y: 0.78, phase: 0.42, radius: 1.1),
      (x: 0.69, y: 0.86, phase: 0.9, radius: 0.9),
    ];
    for (final point in points) {
      final twinkle =
          (math.sin((progress + point.phase) * math.pi * 2) + 1) / 2;
      final center = Offset(size.width * point.x, size.height * point.y);
      final paint = Paint()
        ..color = const Color(0xFFFFEDB3)
            .withValues(alpha: 0.18 + twinkle * 0.48)
        ..strokeWidth = 0.7;
      canvas.drawCircle(center, point.radius * (0.8 + twinkle * 0.5), paint);
      if (point.radius > 1.3) {
        canvas.drawLine(
          center.translate(-point.radius * 2.4, 0),
          center.translate(point.radius * 2.4, 0),
          paint,
        );
        canvas.drawLine(
          center.translate(0, -point.radius * 2.4),
          center.translate(0, point.radius * 2.4),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarlightPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
