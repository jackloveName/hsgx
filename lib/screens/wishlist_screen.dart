import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/bottom_sheet_handle.dart';
import '../components/filter_pill_bar.dart';
import '../components/page_action_button.dart';
import '../components/wishlist/wishlist_empty_state.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_form_screen.dart';

Future<WishEntry?> showWishEntrySheet(
  BuildContext context, {
  WishEntry? initial,
}) {
  return showModalBottomSheet<WishEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddWishSheet(initial: initial),
  );
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key, this.store});

  final AppStore? store;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String _filter = 'all';
  DateTime _summaryMonth = DateTime(DateTime.now().year, DateTime.now().month);

  AppStore get _store => widget.store ?? AppStore.instance;

  static const _tabs = [
    ('all', '全部', appBlue, Color(0xFFEDF2FB)),
    ('pending', '待决定', Color(0xFFC28B35), Color(0xFFFBF3DF)),
    ('decided', '已决定', Color(0xFF607FC7), Color(0xFFEDF2FB)),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final primary = Theme.of(context).colorScheme.primary;
        final softPrimary = Color.lerp(primary, Colors.white, 0.88)!;
        final wishlist = _store.wishlist;
        final viewingCurrentMonth = _isCurrentSummaryMonth;
        final entries =
            wishlist.where((entry) {
              final activityDate = _wishActivityDate(entry);
              final inSelectedMonth =
                  activityDate.year == _summaryMonth.year &&
                  activityDate.month == _summaryMonth.month;
              return switch (_filter) {
                'pending' => entry.status == 'cooling',
                'decided' => entry.status != 'cooling' && inSelectedMonth,
                _ => entry.status == 'cooling' || inSelectedMonth,
              };
            }).toList()..sort((first, second) {
              final firstPending = first.status == 'cooling';
              final secondPending = second.status == 'cooling';
              if (firstPending != secondPending) return firstPending ? -1 : 1;
              if (firstPending) {
                final byRemaining = first.remainingDays.compareTo(
                  second.remainingDays,
                );
                if (byRemaining != 0) return byRemaining;
              }
              return second.createdAtDate.compareTo(first.createdAtDate);
            });
        return PageFrame(
          title: '心愿匣',
          action: PageActionButton(
            buttonKey: const Key('wishlist-add-button'),
            tooltip: '记一个未入匣的心愿',
            label: '记一愿',
            icon: Icons.add_rounded,
            onPressed: _addWish,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WishDecisionOverview(
                wishes: wishlist,
                month: _summaryMonth,
                onPreviousMonth: () => _changeSummaryMonth(-1),
                onNextMonth: _isCurrentSummaryMonth
                    ? null
                    : () => _changeSummaryMonth(1),
              ),
              const SizedBox(height: 14),
              FilterPillBar<String>(
                value: _filter,
                onChanged: (value) => setState(() => _filter = value),
                height: 42,
                fontSize: 10,
                padding: EdgeInsets.zero,
                options: [
                  for (final tab in _tabs)
                    FilterPillOption(
                      value: tab.$1,
                      label: tab.$2,
                      color: tab.$1 == 'all' ? primary : tab.$3,
                      backgroundColor: tab.$1 == 'all' ? softPrimary : tab.$4,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (entries.isEmpty)
                WishlistEmptyState(
                  hasAnyWishes: wishlist.isNotEmpty,
                  emptyTitle: viewingCurrentMonth ? null : '这个月份还没有心愿',
                  emptyDescription: viewingCurrentMonth
                      ? null
                      : '切换到其他月份，或返回本月查看最新心愿。',
                  actionLabel: viewingCurrentMonth ? null : '返回本月',
                  onAdd: _addWish,
                  onShowAll: () {
                    setState(() {
                      _filter = 'all';
                      _summaryMonth = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                      );
                    });
                  },
                )
              else
                for (final entry in entries) ...[
                  _WishCard(
                    key: ValueKey('wish-${entry.id}'),
                    entry: entry,
                    onEdit: () => _editWish(entry),
                    onDelete: () => _delete(entry),
                    onAbandoned: () => _decide(entry, 'abandoned'),
                    onAddItem: () => _addItemFromWish(entry),
                  ),
                  const SizedBox(height: 11),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _addWish() async {
    final entry = await showWishEntrySheet(context);
    if (entry != null) {
      if (!mounted) return;
      await runStoreAction(
        context,
        () => _store.addWish(entry),
        successMessage: '心愿已放入冷静期',
      );
      if (mounted) {
        setState(() {
          _filter = 'all';
          _summaryMonth = DateTime(DateTime.now().year, DateTime.now().month);
        });
      }
    }
  }

  Future<void> _delete(WishEntry entry) async {
    final confirmed = await confirmAction(
      context,
      title: '删除心愿',
      message: '确定删除“${entry.name}”吗？',
      confirmLabel: '删除',
      destructive: true,
    );
    if (confirmed && mounted) {
      await runStoreAction(
        context,
        () => _store.deleteWish(entry.id),
        successMessage: '心愿已删除',
      );
    }
  }

  Future<void> _editWish(WishEntry entry) async {
    final updated = await showWishEntrySheet(context, initial: entry);
    if (updated == null || !mounted) return;
    await runStoreAction(
      context,
      () => _store.updateWish(updated),
      successMessage: entry.status == 'abandoned' ? '心愿已重新放入冷静期' : '心愿已更新',
    );
    if (mounted && entry.status == 'abandoned') {
      setState(() {
        _filter = 'pending';
        _summaryMonth = DateTime(DateTime.now().year, DateTime.now().month);
      });
    }
  }

  Future<void> _decide(WishEntry entry, String status) async {
    await runStoreAction(
      context,
      () => _store.decideWish(entry.id, status),
      successMessage: switch (status) {
        'wanted' => '已确认想要',
        'achieved' => '心愿已完成',
        _ => '已放弃「${entry.name}」，避免花费 ¥${formatMoney(entry.expectedPrice)}',
      },
    );
  }

  Future<void> _addItemFromWish(WishEntry entry) async {
    final item = await Navigator.of(context).push<InventoryItem?>(
      MaterialPageRoute<InventoryItem?>(
        builder: (_) => ItemFormScreen(wish: entry, store: _store),
      ),
    );
    if (item == null || !mounted) return;
    await _store.updateWish(
      entry.copyWith(
        status: 'achieved',
        achievedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  bool get _isCurrentSummaryMonth {
    final now = DateTime.now();
    return _summaryMonth.year == now.year && _summaryMonth.month == now.month;
  }

  void _changeSummaryMonth(int delta) {
    setState(() {
      _summaryMonth = DateTime(_summaryMonth.year, _summaryMonth.month + delta);
    });
  }
}

String _achievedAtLabel(WishEntry entry) {
  final value = entry.achievedAtDate ?? entry.createdAtDate;
  String two(int number) => number.toString().padLeft(2, '0');
  return '${formatDate(value)} ${two(value.hour)}:${two(value.minute)}';
}

DateTime _wishActivityDate(WishEntry entry) {
  if (entry.status == 'achieved') {
    return entry.achievedAtDate ?? entry.createdAtDate;
  }
  return entry.createdAtDate;
}

class _WishDecisionOverview extends StatelessWidget {
  const _WishDecisionOverview({
    required this.wishes,
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final List<WishEntry> wishes;
  final DateTime month;
  final VoidCallback onPreviousMonth;
  final VoidCallback? onNextMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final achievedThisMonth = wishes.where((entry) {
      if (entry.status != 'achieved') return false;
      final activityDate = _wishActivityDate(entry);
      return activityDate.year == month.year &&
          activityDate.month == month.month;
    }).toList();
    final wishSpent = achievedThisMonth.fold<double>(
      0,
      (sum, entry) => sum + entry.expectedPrice,
    );
    return GradientCard(
      key: const Key('wish-spend-overview'),
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WishOverviewHeader(
            title: month.year == now.year && month.month == now.month
                ? '本月心愿花费'
                : '心愿花费',
            monthSwitch: _MonthSwitch(
              month: month,
              onPrevious: onPreviousMonth,
              onNext: onNextMonth,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¥${formatMoney(wishSpent, compact: true)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Songti SC',
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '共实现 ${achievedThisMonth.length} 个心愿',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WishOverviewHeader extends StatelessWidget {
  const _WishOverviewHeader({required this.title, required this.monthSwitch});

  final String title;
  final Widget monthSwitch;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title,
      style: TextStyle(
        color: Colors.white70,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout =
            constraints.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(10) > 13;
        if (useStackedLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: monthSwitch),
            ],
          );
        }
        return Row(children: [text, const Spacer(), monthSwitch]);
      },
    );
  }
}

class _MonthSwitch extends StatelessWidget {
  const _MonthSwitch({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('wish-summary-previous-month'),
            tooltip: '上个月',
            onPressed: onPrevious,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(30, 30),
              maximumSize: const Size(30, 30),
              padding: EdgeInsets.zero,
            ),
            icon: Icon(Icons.chevron_left_rounded, size: 18),
          ),
          Text(
            '${month.year}年${month.month}月',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            key: const Key('wish-summary-next-month'),
            tooltip: '下个月',
            onPressed: onNext,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white30,
              minimumSize: const Size(30, 30),
              maximumSize: const Size(30, 30),
              padding: EdgeInsets.zero,
            ),
            icon: Icon(Icons.chevron_right_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _WishCard extends StatefulWidget {
  const _WishCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onAbandoned,
    required this.onAddItem,
  });

  final WishEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAbandoned;
  final VoidCallback onAddItem;

  @override
  State<_WishCard> createState() => _WishCardState();
}

class _WishCardState extends State<_WishCard> {
  WishEntry get entry => widget.entry;

  Future<void> _confirmAbandonWish() async {
    final confirmed = await confirmAction(
      context,
      title: '放弃这个心愿？',
      message: '放弃后该心愿将标记为“已放弃”，并计入避免花费。',
      confirmLabel: '放弃',
      destructive: true,
    );
    if (confirmed && mounted) {
      widget.onAbandoned();
    }
  }

  Future<void> _confirmAddToWishlist() async {
    final confirmed = await confirmAction(
      context,
      title: '拾入心愿匣？',
      message: '拾入心愿匣后，该心愿状态将变为“已达成”，是否确认操作？',
      confirmLabel: '确认',
    );
    if (confirmed && mounted) {
      widget.onAddItem();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = switch (entry.status) {
      'wanted' => ('确认想要', const Color(0xFF2E7568), const Color(0xFFE7F6F1)),
      'abandoned' => ('已放弃', const Color(0xFFA65F5F), const Color(0xFFFAEDF2)),
      'achieved' => ('已达成', const Color(0xFF607FC7), const Color(0xFFEDF2FB)),
      _ => ('冷静中', const Color(0xFFC28B35), const Color(0xFFFBF3DF)),
    };
    return SoftCard(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _WishDetailSheet(
          entry: entry,
          statusLabel: status.$1,
          statusColor: status.$2,
          statusBackground: status.$3,
          onEdit: () {
            Navigator.pop(sheetContext);
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onEdit(),
            );
          },
          onDelete: () {
            Navigator.pop(sheetContext);
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onDelete(),
            );
          },
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryImage(category: entry.categoryInfo, size: 54),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status.$3,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        status.$1,
                        style: TextStyle(
                          color: status.$2,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.status == 'achieved'
                      ? '${entry.categoryInfo.name} · 达成于 ${_achievedAtLabel(entry)}'
                      : '${entry.categoryInfo.name} · 预计 ¥${formatMoney(entry.expectedPrice)}',
                  style: TextStyle(color: context.appMutedColor, fontSize: 11),
                ),
                if (entry.reason.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.reason.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appMutedColor,
                      fontSize: 10,
                      height: 1.42,
                    ),
                  ),
                ],
                if (entry.status == 'wanted') ...[
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _confirmAbandonWish,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text('放弃', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _confirmAddToWishlist,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text('拾入心愿匣', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
                if (entry.status == 'cooling') ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.coolingDays == 0
                          ? 0
                          : (entry.elapsedDays / entry.coolingDays).clamp(0, 1),
                      minHeight: 5,
                      backgroundColor: context.appSurfaceMutedColor,
                      color: const Color(0xFFC28B35),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '实际已冷静 ${entry.elapsedDays} 天 · ${entry.remainingDays == 0 ? '可以决定了' : '还有 ${entry.remainingDays} 天决定'}',
                    style: TextStyle(
                      color: context.appMutedColor,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _confirmAddToWishlist,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('拾入心愿匣', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _confirmAbandonWish,
                          style: FilledButton.styleFrom(
                            backgroundColor: Color.alphaBlend(
                              Theme.of(context).colorScheme.error
                                  .withValues(alpha: 0.1),
                              context.appSurfaceColor,
                            ),
                            foregroundColor: const Color(0xFFA65F5F),
                            minimumSize: const Size(0, 36),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('放弃', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WishDetailSheet extends StatelessWidget {
  const _WishDetailSheet({
    required this.entry,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.onEdit,
    required this.onDelete,
  });

  final WishEntry entry;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = Color.lerp(primary, context.appSurfaceColor, 0.88)!;
    final reason = entry.reason.trim().isEmpty
        ? '还没有写下想要它的原因。'
        : entry.reason.trim();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryImage(category: entry.categoryInfo, size: 62),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Songti SC',
                            fontSize: 24,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              entry.categoryInfo.name,
                              style: TextStyle(
                                color: context.appMutedColor,
                                fontSize: 11,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusBackground,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('wish-detail-close'),
                    tooltip: '关闭',
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: context.appSurfaceMutedColor,
                      foregroundColor: context.appMutedColor,
                      minimumSize: const Size(36, 36),
                      maximumSize: const Size(36, 36),
                    ),
                    icon: Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                decoration: BoxDecoration(
                  color: softPrimary.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.09)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      color: primary.withValues(alpha: 0.65),
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(
                          color: context.appMutedColor,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: context.appSurfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.appBorderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: MiniMetric(
                        label: entry.status == 'achieved' ? '达成时间' : '预计价格',
                        value: entry.status == 'achieved'
                            ? _achievedAtLabel(entry)
                            : '¥${formatMoney(entry.expectedPrice)}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 38,
                      color: context.appBorderColor,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: MiniMetric(
                        label: '冷静期',
                        value: '${entry.coolingDays} 天',
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.status == 'cooling') ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      const Color(0xFFC79A4A).withValues(alpha: 0.09),
                      context.appSurfaceColor,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFC79A4A).withValues(alpha: 0.24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '冷静进度',
                            style: TextStyle(
                              color: Color(0xFF8C6B2F),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '实际 ${entry.elapsedDays} 天',
                            style: TextStyle(
                              color: Color(0xFF9A8157),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: entry.coolingDays == 0
                              ? 0
                              : (entry.elapsedDays / entry.coolingDays).clamp(
                                  0,
                                  1,
                                ),
                          minHeight: 6,
                          backgroundColor: context.appSurfaceMutedColor,
                          color: const Color(0xFFC79A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.elapsedDays > entry.coolingDays
                            ? '计划冷静 ${entry.coolingDays} 天，目前已超过 ${entry.elapsedDays - entry.coolingDays} 天。'
                            : entry.remainingDays == 0
                            ? '计划冷静 ${entry.coolingDays} 天，已经可以做出决定了。'
                            : '计划冷静 ${entry.coolingDays} 天，还有 ${entry.remainingDays} 天。',
                        style: TextStyle(
                          color: Color(0xFF8B7D67),
                          fontSize: 10,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (entry.status == 'achieved')
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB75A70),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('删除'),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: const Key('wish-detail-edit'),
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          minimumSize: const Size(0, 44),
                          side: BorderSide(
                            color: primary.withValues(alpha: 0.24),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('编辑心愿'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        key: const Key('wish-detail-delete'),
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB75A70),
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          side: BorderSide(
                            color: const Color(0xFFB75A70)
                                .withValues(alpha: 0.28),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('删除'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddWishSheet extends StatefulWidget {
  const _AddWishSheet({this.initial});

  final WishEntry? initial;

  @override
  State<_AddWishSheet> createState() => _AddWishSheetState();
}

class _AddWishSheetState extends State<_AddWishSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _reason;
  late String _category;
  late int _coolingDays;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _price = TextEditingController(
      text: initial == null ? '' : formatMoney(initial.expectedPrice),
    );
    _reason = TextEditingController(text: initial?.reason ?? '');
    _category = initial?.category ?? 'digital';
    _coolingDays = initial?.coolingDays ?? 7;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final movingBackToWishlist = widget.initial?.status == 'abandoned';
    final keyboardInset = media.viewInsets.bottom;
    final availableHeight =
        media.size.height - keyboardInset - media.padding.top;
    final maxHeight = keyboardInset > 0
        ? math.min(520.0, math.max(220.0, availableHeight * 0.62))
        : math.min(720.0, media.size.height * 0.84);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          key: const Key('wish-form-sheet'),
          decoration: BoxDecoration(
            color: context.appSurfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BottomSheetHandle(),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Theme.of(context).colorScheme.primary,
                            Colors.white,
                            0.86,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          widget.initial == null
                              ? Icons.favorite_border_rounded
                              : Icons.edit_note_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.initial == null ? '记一愿' : '编辑心愿',
                              style: TextStyle(
                                fontFamily: 'Songti SC',
                                fontSize: 24,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: context.appSurfaceMutedColor,
                          foregroundColor: context.appMutedColor,
                          minimumSize: const Size(36, 36),
                          maximumSize: const Size(36, 36),
                        ),
                        icon: Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _WishFormSection(
                    icon: Icons.inventory_2_outlined,
                    title: '心愿内容',
                    subtitle: '记下它为什么进入你的生活',
                    child: Column(
                      children: [
                        TextField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '想要什么',
                            hintText: '例如：一台掌上游戏机',
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: BottomSelectField<String>(
                                label: '分类',
                                value: _category,
                                options: [
                                  for (final category in itemCategories)
                                    BottomSelectOption(
                                      value: category.id,
                                      label: category.name,
                                      leading: Image.asset(
                                        category.asset,
                                        width: 28,
                                        height: 28,
                                      ),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _category = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: _price,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: '预计价格',
                                  prefixText: '¥ ',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        TextField(
                          controller: _reason,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: '为什么想要',
                            hintText: '写下真实用途，帮助未来的自己判断',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _WishFormSection(
                    icon: Icons.hourglass_empty_rounded,
                    title: '冷静计划',
                    subtitle: '给决定留出一点距离',
                    child: Column(
                      children: [
                        BottomSelectField<int>(
                          label: '冷静期',
                          value: _coolingDays,
                          options: const [
                            BottomSelectOption(value: 3, label: '3 天'),
                            BottomSelectOption(value: 7, label: '7 天'),
                            BottomSelectOption(value: 14, label: '14 天'),
                            BottomSelectOption(value: 30, label: '30 天'),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _coolingDays = value);
                            }
                          },
                        ),
                        const SizedBox(height: 11),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              const Color(0xFFC79A4A).withValues(alpha: 0.09),
                              context.appSurfaceColor,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                color: Color(0xFFB18842),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '冷静期结束后再决定。期间随时可以回来调整。',
                                  style: TextStyle(
                                    color: const Color(0xFF8B7D67)
                                        .withValues(alpha: 0.95),
                                    fontSize: 10,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: '保存',
                    onPressed: () {
                      final name = _name.text.trim();
                      if (name.isEmpty) {
                        showAppSnack(context, '请填写心愿名称');
                        return;
                      }
                      if (_price.text.trim().isEmpty) {
                        showAppSnack(context, '请填写预计价格');
                        return;
                      }
                      final price = double.tryParse(
                        _price.text.replaceAll(',', ''),
                      );
                      if (price == null || price < 0) {
                        showAppSnack(context, '请输入有效的预计价格');
                        return;
                      }
                      final now = DateTime.now().toIso8601String();
                      Navigator.pop(
                        context,
                        WishEntry(
                          id:
                              widget.initial?.id ??
                              'wish_${DateTime.now().microsecondsSinceEpoch}',
                          name: name,
                          category: _category,
                          expectedPrice: price,
                          reason: _reason.text.trim(),
                          coolingDays: _coolingDays,
                          createdAt: movingBackToWishlist
                              ? now
                              : widget.initial?.createdAt ?? now,
                          status: movingBackToWishlist
                              ? 'cooling'
                              : widget.initial?.status ?? 'cooling',
                          desireType: widget.initial?.desireType ?? '',
                          achievedAt: widget.initial?.achievedAt ?? '',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WishFormSection extends StatelessWidget {
  const _WishFormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = Color.lerp(primary, context.appSurfaceColor, 0.87)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A4032).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: softPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.appMutedColor,
                        fontSize: 9,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}
