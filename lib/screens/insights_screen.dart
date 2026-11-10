import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../app_store.dart';
import '../components/guest_page_banner.dart';
import '../domain/insights_summary.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'insight_items_screen.dart';
import 'item_detail_screen.dart';
import 'login_screen.dart';
import 'recovery_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  InsightsPeriod _period = InsightsPeriod.last30;
  int _snapshotRevision = -1;
  InsightsPeriod? _snapshotPeriod;
  InsightsSnapshot? _snapshot;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final items = store.items;
    if (store.isGuest && items.isEmpty) {
      return _GuestInsightsPreview(
        remainingAdds: store.guestAddsRemaining,
        expiresSoon: store.guestExpiryWarning,
        onAdd: () => MainShell.of(context).openAddItem(),
        onLogin: () => _openLogin(context),
      );
    }
    final revision = store.dataRevision;
    if (_snapshot == null ||
        _snapshotRevision != revision ||
        _snapshotPeriod != _period) {
      _snapshot = InsightsSnapshot.build(items, period: _period);
      _snapshotRevision = revision;
      _snapshotPeriod = _period;
    }
    final snapshot = _snapshot!;
    return AppBackdrop(
      child: SafeArea(
        bottom: false,
        child: ContentPane(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 116),
            children: [
              _InsightsHeader(
                period: _period,
                onPeriodChanged: (period) => setState(() => _period = period),
              ),
              if (store.isGuest) ...[
                const SizedBox(height: 14),
                GuestPageBanner(
                  subtitle: store.guestExpiryWarning
                      ? '本地数据即将到期 · 洞察基于本机记录'
                      : '洞察基于本机 ${items.length} 件物品',
                  remainingAdds: store.guestAddsRemaining,
                  onLogin: () => _openLogin(context),
                ),
              ],
              const SizedBox(height: 17),
              _InsightOverviewCard(snapshot: snapshot),
              const SectionHeading(title: '值得重新看看'),
              if (snapshot.alerts.isEmpty)
                const _AllClearCard()
              else
                _AlertGroup(
                  alerts: snapshot.alerts.take(3).toList(),
                  onTap: (alert) => _handleAlert(context, alert),
                ),
              if (snapshot.usedCount > 0) ...[
                const SectionHeading(title: '它们的日常价值'),
                _CostValueCard(snapshot: snapshot),
              ],
              if (snapshot.hasEnoughData) ...[
                const SectionHeading(title: '物品进入生活的节奏'),
                _PurchaseRhythmCard(snapshot: snapshot),
                const SectionHeading(title: '再往里看一层'),
                _DetailedInsights(snapshot: snapshot),
              ] else ...[
                const SectionHeading(title: '再多记录一点'),
                _EarlyDataGuide(itemCount: snapshot.totalCount),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleAlert(BuildContext context, InsightAlert alert) {
    switch (alert.action) {
      case InsightAlertAction.item ||
          InsightAlertAction.warranty ||
          InsightAlertAction.stock ||
          InsightAlertAction.unused ||
          InsightAlertAction.target:
        final item = alert.itemId == null
            ? null
            : AppStore.instance.itemById(alert.itemId!);
        if (item != null) _openItem(context, item.id);
      case InsightAlertAction.recovery || InsightAlertAction.idle:
        _push(context, const RecoveryScreen());
      case InsightAlertAction.expiring:
        _openList(context, 'expiring');
      case InsightAlertAction.expired:
        _openList(context, 'expired');
      case InsightAlertAction.lowStock:
        _openList(context, 'low-stock');
      case InsightAlertAction.duplicate:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => InsightItemsScreen(
              type: 'warning',
              category: alert.category ?? '',
              subcategory: alert.subcategory ?? '',
              subcategoryLabel: alert.subcategory ?? '',
            ),
          ),
        );
    }
  }

  void _openList(BuildContext context, String type) {
    _push(context, InsightItemsScreen(type: type));
  }

  void _openItem(BuildContext context, String itemId) {
    _push(context, ItemDetailScreen(itemId: itemId));
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _openLogin(BuildContext context) async {
    final synced = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const LoginScreen()));
    if (synced == true && context.mounted) {
      MainShell.of(context).selectTab(0);
      showAppSnack(context, '登录成功，本机记录继续保存在当前设备');
    }
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader({required this.period, required this.onPeriodChanged});

  final InsightsPeriod period;
  final ValueChanged<InsightsPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '匣中光景',
          style: TextStyle(
            fontFamily: 'Songti SC',
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '看见这一匣里的物品如何参与生活',
          style: TextStyle(color: appMuted, fontSize: 10),
        ),
        const SizedBox(height: 14),
        _PeriodSwitcher(value: period, onChanged: onPeriodChanged),
      ],
    );
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.value, required this.onChanged});

  final InsightsPeriod value;
  final ValueChanged<InsightsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = AppThemeTokens.of(context).softPrimary;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        children: [
          for (final period in InsightsPeriod.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(period),
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: period == value ? softPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    period.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: period == value ? primary : appMuted,
                      fontSize: 10,
                      fontWeight: period == value
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightOverviewCard extends StatelessWidget {
  const _InsightOverviewCard({required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '这一匣的最近光景',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                snapshot.period.label,
                style: const TextStyle(color: Colors.white60, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Songti SC',
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.55,
            ),
          ),
          if (snapshot.foreignCurrencyItemCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              '金额分析仅合计人民币，另有 '
              '${snapshot.foreignCurrencyItemCount} 件外币物品',
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            ),
          ],
          if (snapshot.activeCount > 0) ...[
            const SizedBox(height: 16),
            _StatusOverview(snapshot: snapshot),
          ],
          const SizedBox(height: 17),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MiniMetric(
                  label: '使用率',
                  value: '${(snapshot.usageRate * 100).round()}%',
                  dark: true,
                ),
              ),
              Expanded(
                child: MiniMetric(
                  label: '本期使用',
                  value: '${snapshot.periodUsageDays} 天',
                  dark: true,
                ),
              ),
              Expanded(
                child: MiniMetric(
                  label: '闲置占用',
                  value: '¥${formatMoney(snapshot.idleValue, compact: true)}',
                  dark: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _title {
    if (snapshot.activeCount == 0) return '还没有可分析的物品';
    if (snapshot.usageRate >= 0.75) return '这些物品正在参与生活';
    if (snapshot.usageRate >= 0.4) return '生活资产保持流动';
    return '有些物品正在停下来';
  }

  String get _message {
    if (snapshot.activeCount == 0) {
      return '记录一件正在使用的物品，使用率、成本和持有变化会从这里开始。';
    }
    if (snapshot.usedCount == 0) {
      return '${snapshot.activeCount} 件生活物品在本期还没有使用记录，可以从一件开始。';
    }
    return '${snapshot.activeCount} 件生活物品中，${snapshot.usedCount} 件在本期被使用。';
  }
}

class _StatusOverview extends StatelessWidget {
  const _StatusOverview({required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final entries = [
      (label: '使用中', count: snapshot.inUseCount, status: itemStatuses[0]),
      (label: '闲置', count: snapshot.idleCount, status: itemStatuses[1]),
      (label: '维修中', count: snapshot.repairingCount, status: itemStatuses[2]),
    ].where((entry) => entry.count > 0).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final entry in entries)
                  Expanded(
                    flex: entry.count,
                    child: ColoredBox(color: entry.status.color),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 13,
          runSpacing: 5,
          children: [
            for (final entry in entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: entry.status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${entry.label} ${entry.count}',
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _AlertGroup extends StatelessWidget {
  const _AlertGroup({required this.alerts, required this.onTap});

  final List<InsightAlert> alerts;
  final ValueChanged<InsightAlert> onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < alerts.length; index++) ...[
            _AlertRow(alert: alerts[index], onTap: () => onTap(alerts[index])),
            if (index < alerts.length - 1)
              const Divider(height: 1, indent: 66, color: Color(0xFFF1EDE7)),
          ],
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert, required this.onTap});

  final InsightAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final icon = switch (alert.action) {
      InsightAlertAction.item => Icons.open_in_new_rounded,
      InsightAlertAction.warranty => Icons.event_available_outlined,
      InsightAlertAction.stock => Icons.inventory_2_outlined,
      InsightAlertAction.idle => Icons.recycling_rounded,
      InsightAlertAction.unused => Icons.visibility_off_outlined,
      InsightAlertAction.target => Icons.flag_outlined,
      InsightAlertAction.recovery => Icons.recycling_rounded,
      InsightAlertAction.expiring => Icons.schedule_rounded,
      InsightAlertAction.expired => Icons.history_toggle_off_rounded,
      InsightAlertAction.lowStock => Icons.inventory_2_outlined,
      InsightAlertAction.duplicate => Icons.content_copy_rounded,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: primary, size: 19),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.label,
                      style: TextStyle(
                        color: primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: appMuted,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB9B4AC),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllClearCard extends StatelessWidget {
  const _AllClearCard();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.check_rounded, color: primary, size: 21),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '暂时没有需要处理的物品',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  '继续记录使用，更准确的趋势会慢慢出现。',
                  style: TextStyle(color: appMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CostValueCard extends StatelessWidget {
  const _CostValueCard({required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasTarget = snapshot.targetDailyCost > 0;
    final comparison = hasTarget && snapshot.actualDailyCost > 0
        ? (snapshot.actualDailyCost - snapshot.targetDailyCost) /
              snapshot.targetDailyCost
        : null;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '使用日均',
                      style: TextStyle(color: appMuted, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${formatMoney(snapshot.actualDailyCost)}',
                      style: TextStyle(
                        color: primary,
                        fontFamily: 'Songti SC',
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasTarget)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    comparison == null
                        ? '目标 ¥${formatMoney(snapshot.targetDailyCost)} / 天'
                        : comparison <= 0
                        ? '比目标低 ${(comparison.abs() * 100).round()}%'
                        : '比目标高 ${(comparison * 100).round()}%',
                    style: TextStyle(
                      color: primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: hasTarget
                  ? math.min(
                      1,
                      snapshot.actualDailyCost / snapshot.targetDailyCost,
                    )
                  : 0.55,
              minHeight: 7,
              backgroundColor: const Color(0xFFF0ECE6),
              color: primary,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            hasTarget
                ? '目标为 ¥${formatMoney(snapshot.targetDailyCost)} / 天，越低的实际日均代表越充分地使用。'
                : '补上目标使用天数后，就能看到实际成本与目标之间的差距。',
            style: const TextStyle(color: appMuted, fontSize: 10, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PurchaseRhythmCard extends StatelessWidget {
  const _PurchaseRhythmCard({required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final maxValue = snapshot.purchaseTrend.fold<double>(
      1,
      (max, entry) => math.max(max, entry.value),
    );
    final change = snapshot.purchaseChange;
    final comparison = change == null
        ? snapshot.period == InsightsPeriod.all
              ? '全部记录累计'
              : snapshot.periodPurchaseAmount == 0
              ? '本期没有购入'
              : '上一周期没有购入'
        : change == 0
        ? '与上一周期持平'
        : change > 0
        ? '比${snapshot.period.comparisonLabel}增加 ${(change * 100).round()}%'
        : '比${snapshot.period.comparisonLabel}减少 ${(change.abs() * 100).round()}%';
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本期购入',
                      style: TextStyle(color: appMuted, fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${formatMoney(snapshot.periodPurchaseAmount, compact: true)}',
                      style: const TextStyle(
                        fontFamily: 'Songti SC',
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${snapshot.periodPurchaseCount} 件',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comparison,
            style: const TextStyle(color: appMuted, fontSize: 10),
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 128,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in snapshot.purchaseTrend)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          entry.value == 0
                              ? ''
                              : '¥${formatMoney(entry.value, compact: true)}',
                          style: const TextStyle(color: appMuted, fontSize: 8),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: math.max(5, entry.value / maxValue * 72),
                          width: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: entry.value > 0
                                  ? [primary.withValues(alpha: 0.55), primary]
                                  : [
                                      const Color(0xFFF0ECE6),
                                      const Color(0xFFF0ECE6),
                                    ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.label,
                          style: const TextStyle(color: appMuted, fontSize: 9),
                        ),
                      ],
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

class _DetailedInsights extends StatelessWidget {
  const _DetailedInsights({required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final holdingLabels = ['少于 1 个月', '1~6 个月', '6 个月~1 年', '1~3 年', '3 年以上'];
    return SoftCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: Theme.of(context).colorScheme.primary,
        collapsedIconColor: appMuted,
        title: const Text(
          '资产分布与持有结构',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        subtitle: const Text(
          '展开查看分类、持有时间和分类日均成本',
          style: TextStyle(color: appMuted, fontSize: 9),
        ),
        children: [
          _DetailTitle(title: '资产分布'),
          if (snapshot.categories.isEmpty)
            const _NoData()
          else ...[
            _DistributionBar(categories: snapshot.categories),
            const SizedBox(height: 14),
            for (final entry in snapshot.categories.take(5)) ...[
              _CategoryRow(entry: entry),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 8),
          _DetailTitle(title: '持有时间'),
          if (snapshot.totalCount == 0)
            const _NoData()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < holdingLabels.length; index++)
                  if (snapshot.holdingCounts[index] > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppThemeTokens.of(context).softPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${holdingLabels[index]} · '
                        '${snapshot.holdingCounts[index]} 件',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
              ],
            ),
          if (snapshot.categories.isNotEmpty) ...[
            const SizedBox(height: 20),
            _DetailTitle(title: '分类拥有日均'),
            for (final entry in ([
              ...snapshot.categories,
            ]..sort((a, b) => b.dailyCost.compareTo(a.dailyCost))).take(5)) ...[
              _CostRow(entry: entry),
              const SizedBox(height: 11),
            ],
          ],
        ],
      ),
    );
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text('暂无数据', style: TextStyle(color: appMuted, fontSize: 11)),
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({required this.categories});

  final List<InsightCategoryMetric> categories;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            for (final entry in categories)
              Expanded(
                flex: math.max(1, (entry.ratio * 1000).round()),
                child: ColoredBox(color: entry.category.color),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.entry});

  final InsightCategoryMetric entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: entry.category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            entry.category.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${(entry.ratio * 100).round()}%',
          style: const TextStyle(color: appMuted, fontSize: 9),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            '¥${formatMoney(entry.value, compact: true)}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.entry});

  final InsightCategoryMetric entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: entry.category.softColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            Icons.auto_graph_rounded,
            size: 15,
            color: entry.category.color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            entry.category.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '¥${formatMoney(entry.dailyCost)} / 天',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _EarlyDataGuide extends StatelessWidget {
  const _EarlyDataGuide({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = AppThemeTokens.of(context).softPrimary;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemCount == 0 ? '数据会从第一件物品开始' : '当前数据还比较少',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            '多记录几件物品后，购买趋势、分类对比和持有结构才会更有参考价值。',
            style: TextStyle(color: appMuted, fontSize: 10, height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _GuideStep(
                icon: Icons.photo_camera_outlined,
                label: '记录照片',
                color: primary,
                background: softPrimary,
              ),
              const SizedBox(width: 8),
              _GuideStep(
                icon: Icons.timeline_rounded,
                label: '持续使用',
                color: primary,
                background: softPrimary,
              ),
              const SizedBox(width: 8),
              _GuideStep(
                icon: Icons.flag_outlined,
                label: '设置目标',
                color: primary,
                background: softPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestInsightsPreview extends StatelessWidget {
  const _GuestInsightsPreview({
    required this.remainingAdds,
    required this.expiresSoon,
    required this.onAdd,
    required this.onLogin,
  });

  final int remainingAdds;
  final bool expiresSoon;
  final VoidCallback onAdd;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = AppThemeTokens.of(context).softPrimary;
    return AppBackdrop(
      child: SafeArea(
        bottom: false,
        child: ContentPane(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 116),
            children: [
              GuestPageBanner(
                subtitle: expiresSoon
                    ? '本地数据即将到期 · 洞察只分析本机记录'
                    : '还可添加 $remainingAdds 次 · 洞察只分析本机记录',
                remainingAdds: remainingAdds,
                onLogin: onLogin,
              ),
              const SizedBox(height: 16),
              GradientCard(
                child: Stack(
                  children: [
                    Positioned(
                      right: -28,
                      top: -36,
                      child: Opacity(
                        opacity: 0.12,
                        child: Icon(
                          Icons.auto_graph_rounded,
                          color: Colors.white,
                          size: 170,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '从第一件物品开始',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Songti SC',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          '记录后会自动生成使用率、成本对比和可行动的提醒。',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: onAdd,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primary,
                            minimumSize: const Size(0, 42),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            remainingAdds > 0 ? '添加第一件物品' : '登录后继续添加',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SectionHeading(title: '记录之后，你会看到'),
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _GuestFeature(
                      icon: Icons.donut_large_rounded,
                      title: '真实使用率',
                      description: '看见哪些物品正在参与生活。',
                      color: primary,
                      background: softPrimary,
                    ),
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: Color(0xFFF1EDE7),
                    ),
                    _GuestFeature(
                      icon: Icons.schedule_rounded,
                      title: '成本与期限',
                      description: '把花费换算成每天，并提前看到期限。',
                      color: primary,
                      background: softPrimary,
                    ),
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: Color(0xFFF1EDE7),
                    ),
                    _GuestFeature(
                      icon: Icons.auto_awesome_rounded,
                      title: '可行动建议',
                      description: '优先告诉你哪些物品值得处理。',
                      color: primary,
                      background: softPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestFeature extends StatelessWidget {
  const _GuestFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: appMuted, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
