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
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
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
                    onPeriodChanged: (period) =>
                        setState(() => _period = period),
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
                  InsightsRecentSceneCard(snapshot: snapshot),
                  const SectionHeading(title: '值得重新看看'),
                  if (snapshot.alerts.isEmpty)
                    const _AllClearCard()
                  else
                    _AlertGroup(
                      alerts: snapshot.alerts.take(3).toList(),
                      onTap: (alert) => _handleAlert(context, alert),
                    ),
                  if (snapshot.hasEnoughData) ...[
                    const SectionHeading(title: '物品进入生活的节奏'),
                    _PurchaseRhythmCard(snapshot: snapshot),
                    const SectionHeading(title: '再往里看一层'),
                    InsightsDetailsSection(snapshot: snapshot),
                  ] else ...[
                    const SectionHeading(title: '再多记录一点'),
                    _EarlyDataGuide(itemCount: snapshot.totalCount),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
    return _PeriodSwitcher(value: period, onChanged: onPeriodChanged);
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
        color: context.appSurfaceColor.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorderColor),
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
                      color: period == value ? primary : context.appMutedColor,
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

class InsightsRecentSceneCard extends StatelessWidget {
  const InsightsRecentSceneCard({super.key, required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ringSize = constraints.maxWidth < 280 ? 76.0 : 92.0;
          return Column(
            key: const Key('insights-recent-scene'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
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
                    style: TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Songti SC',
                            fontSize: constraints.maxWidth < 280 ? 23 : 25,
                            height: 1.22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.55,
                          ),
                        ),
                        if (snapshot.foreignCurrencyItemCount > 0) ...[
                          const SizedBox(height: 5),
                          Text(
                            '金额分析仅合计人民币，另有 '
                            '${snapshot.foreignCurrencyItemCount} 件外币物品',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: constraints.maxWidth < 280 ? 10 : 14),
                  _UsageRateRing(rate: snapshot.usageRate, size: ringSize),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SceneMetric(
                      value: '${snapshot.inUseCount} 件',
                      label: '正在使用',
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _SceneMetric(
                      value: '${snapshot.periodUsageDays} 天',
                      label: '本期使用',
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _SceneMetric(
                      value:
                          '¥${formatMoney(snapshot.idleValue, compact: true)}',
                      label: '闲置占用',
                    ),
                  ),
                ],
              ),
            ],
          );
        },
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
    return '${snapshot.activeCount} 件生活物品中，'
        '${snapshot.usedCount} 件在本期被使用，让收藏继续参与日常。';
  }
}

class _UsageRateRing extends StatelessWidget {
  const _UsageRateRing({required this.rate, required this.size});

  final double rate;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = AppThemeTokens.of(context).heroAccent;
    final normalized = rate.clamp(0, 1).toDouble();
    return Semantics(
      label: '使用率 ${(normalized * 100).round()}%',
      child: SizedBox.square(
        key: const Key('insights-usage-ring'),
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _UsageRateRingPainter(rate: normalized, color: accent),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(normalized * 100).round()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Songti SC',
                    fontSize: size < 84 ? 19 : 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '使用率',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageRateRingPainter extends CustomPainter {
  const _UsageRateRingPainter({required this.rate, required this.color});

  final double rate;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 7.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - strokeWidth / 2,
    );
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(rect.center, rect.width / 2, track);

    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * rate, false, progress);
  }

  @override
  bool shouldRepaint(covariant _UsageRateRingPainter oldDelegate) {
    return oldDelegate.rate != rate || oldDelegate.color != color;
  }
}

class _SceneMetric extends StatelessWidget {
  const _SceneMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
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
            if (index < alerts.length - 1) const ContentDivider(indent: 66),
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
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMutedColor,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(
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
          Expanded(
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
                  style: TextStyle(color: context.appMutedColor, fontSize: 10),
                ),
              ],
            ),
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
                child: Text(
                  '¥${formatMoney(snapshot.periodPurchaseAmount, compact: true)}',
                  style: TextStyle(
                    fontFamily: 'Songti SC',
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
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
            style: TextStyle(color: context.appMutedColor, fontSize: 10),
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
                          style: TextStyle(
                            color: context.appMutedColor,
                            fontSize: 8,
                          ),
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
          ),
        ],
      ),
    );
  }
}

class InsightsDetailsSection extends StatelessWidget {
  const InsightsDetailsSection({super.key, required this.snapshot});

  final InsightsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final holdingLabels = ['少于 1 个月', '1~6 个月', '6 个月~1 年', '1~3 年', '3 年以上'];
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DetailTitle(title: '资产分布'),
          if (snapshot.categories.isEmpty)
            const _NoData()
          else
            _AssetDistributionPie(categories: snapshot.categories),
          const SizedBox(height: 20),
          const _DetailTitle(title: '持有时间'),
          if (snapshot.totalCount == 0)
            const _NoData()
          else
            _HoldingTimeChart(
              labels: holdingLabels,
              counts: snapshot.holdingCounts,
            ),
          if (snapshot.categories.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _DetailTitle(title: '分类拥有日均'),
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
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: context.appMutedColor, fontSize: 11),
        ),
      ),
    );
  }
}

class _AssetDistributionPie extends StatelessWidget {
  const _AssetDistributionPie({required this.categories});

  final List<InsightCategoryMetric> categories;

  @override
  Widget build(BuildContext context) {
    const visibleCount = 4;
    final visible = categories.take(visibleCount).toList();
    final remaining = categories.skip(visibleCount).toList();
    final total = categories.fold<double>(0, (sum, entry) => sum + entry.value);
    final slices = <_AssetSlice>[
      for (final entry in visible)
        _AssetSlice(
          label: entry.category.name,
          color: entry.category.color,
          value: entry.value,
          ratio: total <= 0 ? 0 : entry.value / total,
        ),
      if (remaining.isNotEmpty)
        _AssetSlice(
          label: '其余 ${remaining.length} 类',
          color: context.appMutedColor,
          value: remaining.fold<double>(0, (sum, entry) => sum + entry.value),
          ratio:
              (remaining.fold<double>(0, (sum, entry) => sum + entry.value) /
                      total)
                  .clamp(0, 1),
        ),
    ];
    final chart = _AssetPieChart(slices: slices);
    final legend = Column(
      children: [
        for (var index = 0; index < slices.length; index++) ...[
          _AssetLegendRow(slice: slices[index]),
          if (index != slices.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(children: [chart, const SizedBox(height: 16), legend]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            chart,
            const SizedBox(width: 22),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _AssetSlice {
  const _AssetSlice({
    required this.label,
    required this.color,
    required this.value,
    required this.ratio,
  });

  final String label;
  final Color color;
  final double value;
  final double ratio;
}

class _AssetPieChart extends StatelessWidget {
  const _AssetPieChart({required this.slices});

  final List<_AssetSlice> slices;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: slices
          .map((slice) => '${slice.label} ${(slice.ratio * 100).round()}%')
          .join('，'),
      child: SizedBox.square(
        key: const Key('insights-asset-pie'),
        dimension: 132,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _AssetPiePainter(
                  slices: slices,
                  trackColor: context.appSurfaceMutedColor,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${slices.length} 类',
                  style: TextStyle(
                    fontFamily: 'Songti SC',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '资产',
                  style: TextStyle(color: context.appMutedColor, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetPiePainter extends CustomPainter {
  const _AssetPiePainter({required this.slices, required this.trackColor});

  final List<_AssetSlice> slices;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 18.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - strokeWidth / 2,
    );
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(rect.center, rect.width / 2, track);

    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = slice.ratio * math.pi * 2;
      if (sweep <= 0) continue;
      final gap = math.min(0.025, sweep * 0.18);
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(0, sweep - gap),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _AssetPiePainter oldDelegate) {
    return oldDelegate.slices != slices || oldDelegate.trackColor != trackColor;
  }
}

class _AssetLegendRow extends StatelessWidget {
  const _AssetLegendRow({required this.slice});

  final _AssetSlice slice;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            slice.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(slice.ratio * 100).round()}%',
          style: TextStyle(color: context.appMutedColor, fontSize: 9),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 58,
          child: Text(
            '¥${formatMoney(slice.value, compact: true)}',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _HoldingTimeChart extends StatelessWidget {
  const _HoldingTimeChart({required this.labels, required this.counts});

  final List<String> labels;
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = Theme.of(context).colorScheme.secondary;
    final maxCount = math.max(
      1,
      counts.fold<int>(0, (max, count) => math.max(max, count)),
    );
    return Semantics(
      label: [
        for (var index = 0; index < labels.length; index++)
          '${labels[index]} ${counts[index]} 件',
      ].join('，'),
      child: SizedBox(
        key: const Key('insights-holding-chart'),
        height: 122,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < labels.length; index++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Text(
                        '${counts[index]}',
                        style: TextStyle(
                          color: counts[index] > 0
                              ? context.appTextColor
                              : context.appMutedColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            width: 24,
                            height: counts[index] == 0
                                ? 4
                                : math.max(8, counts[index] / maxCount * 58),
                            decoration: BoxDecoration(
                              color: counts[index] == 0
                                  ? context.appSurfaceMutedColor
                                  : Color.lerp(
                                      primary,
                                      accent,
                                      index / (labels.length - 1),
                                    ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        height: 26,
                        child: Text(
                          labels[index],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appMutedColor,
                            fontSize: 8,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '¥${formatMoney(entry.dailyCost)} / 天',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            '多记录几件物品后，购买趋势、分类对比和持有结构才会更有参考价值。',
            style: TextStyle(
              color: context.appMutedColor,
              fontSize: 10,
              height: 1.45,
            ),
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
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
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
                          child: Icon(
                            Icons.insights_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '从第一件物品开始',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Songti SC',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
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
                          icon: Icon(Icons.add_rounded, size: 18),
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
                    const ContentDivider(indent: 64),
                    _GuestFeature(
                      icon: Icons.schedule_rounded,
                      title: '成本与期限',
                      description: '把花费换算成每天，并提前看到期限。',
                      color: primary,
                      background: softPrimary,
                    ),
                    const ContentDivider(indent: 64),
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(color: context.appMutedColor, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
