import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final groups = _buildGroups(AppStore.instance);
        final allBadges = groups.expand((group) => group.badges).toList();
        final unlocked = allBadges.where((badge) => badge.unlocked).length;
        return PageFrame(
          title: '徽章',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                colors: const [Color(0xFF7E6BC4), Color(0xFFE28A9E)],
                child: Row(
                  children: [
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 5,
                            color: Colors.white24,
                          ),
                          CircularProgressIndicator(
                            value: allBadges.isEmpty
                                ? 0
                                : unlocked / allBadges.length,
                            strokeWidth: 5,
                            color: const Color(0xFFFFF0B0),
                            backgroundColor: Colors.transparent,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$unlocked',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '/ ${allBadges.length}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unlocked > 0
                                ? '匣中已经亮起 $unlocked 枚星光'
                                : '第一枚生活星光等你点亮',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
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
              for (final group in groups) ...[
                SectionHeading(
                  title: group.name,
                  trailing: Text(
                    '${group.unlocked}/${group.badges.length}',
                    style: const TextStyle(color: appMuted, fontSize: 10),
                  ),
                ),
                Text(
                  group.description,
                  style: const TextStyle(color: appMuted, fontSize: 10),
                ),
                const SizedBox(height: 11),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.76,
                  ),
                  itemCount: group.badges.length,
                  itemBuilder: (context, index) =>
                      _BadgeCard(badge: group.badges[index]),
                ),
              ],
            ],
          ),
        );
      },
    );
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
    final recoveredValue = items.fold<double>(
      0,
      (sum, item) => sum + item.disposalPrice,
    );
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
        description: '收藏匣一点点变满',
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
            items.length,
            10,
          ),
          _badge(
            'century',
            '满',
            '百件藏品',
            '收藏一百件生活物品',
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
            '收藏十件物品',
            0xFFE7849A,
            favoriteCount,
            10,
          ),
          _badge(
            'half-century',
            '半',
            '半百收藏',
            '累计收藏五十件物品',
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
        description: '让每件物品认真上班',
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
        description: '购物脑和冷静脑握手',
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
        description: '见证物品的每一段旅程',
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
        description: '把生活拾进档案里',
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
    required this.description,
    required this.color,
    required this.badges,
  });

  final String name;
  final String description;
  final Color color;
  final List<_BadgeData> badges;

  int get unlocked => badges.where((badge) => badge.unlocked).length;
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

  bool get unlocked => value >= target;
  double get progress => target <= 0 ? 0 : (value / target).clamp(0, 1);
  String get progressText => value >= target
      ? '已点亮'
      : '${value.round().clamp(0, target.round())}/${target.round()}';
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final _BadgeData badge;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      color: badge.unlocked
          ? badge.color.withValues(alpha: 0.06)
          : Colors.white,
      borderColor: badge.unlocked
          ? badge.color.withValues(alpha: 0.25)
          : appBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badge.unlocked
                      ? badge.color.withValues(alpha: 0.14)
                      : const Color(0xFFF2EFEB),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge.glyph,
                  style: TextStyle(
                    color: badge.unlocked
                        ? badge.color
                        : const Color(0xFFB4AEA7),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                badge.unlocked ? '已点亮' : '待发现',
                style: TextStyle(
                  color: badge.unlocked ? badge.color : appMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            badge.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: appMuted, fontSize: 10, height: 1.45),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: badge.progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1EEE9),
              color: badge.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.progressText,
            style: const TextStyle(color: appMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
