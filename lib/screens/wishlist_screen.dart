import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/filter_pill_bar.dart';
import '../components/page_action_button.dart';
import '../models.dart';
import '../widgets.dart';

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
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String _filter = 'pending';

  static const _tabs = [
    ('pending', '待决定', Color(0xFFC28B35), Color(0xFFFBF3DF)),
    ('decided', '已决定', Color(0xFF607FC7), Color(0xFFEDF2FB)),
    ('all', '全部', appBlue, Color(0xFFEDF2FB)),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final primary = Theme.of(context).colorScheme.primary;
        final softPrimary = Color.lerp(primary, Colors.white, 0.88)!;
        final wishlist = AppStore.instance.wishlist;
        final entries =
            wishlist.where((entry) {
              return switch (_filter) {
                'pending' => entry.status == 'cooling',
                'decided' => entry.status != 'cooling',
                _ => true,
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
                avoidedAmount: AppStore.instance.avoidedAmount,
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
                  onAdd: _addWish,
                  onShowAll: () => setState(() => _filter = 'all'),
                )
              else
                for (final entry in entries) ...[
                  _WishCard(
                    key: ValueKey('wish-${entry.id}'),
                    entry: entry,
                    onEdit: () => _editWish(entry),
                    onDelete: () => _delete(entry),
                    onWanted: () => _decide(entry, 'wanted'),
                    onAbandoned: () => _decide(entry, 'abandoned'),
                    onExtend: () => _extendCooling(entry),
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
        () => AppStore.instance.addWish(entry),
        successMessage: '心愿已放入冷静期',
      );
      if (mounted) setState(() => _filter = 'pending');
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
        () => AppStore.instance.deleteWish(entry.id),
        successMessage: '心愿已删除',
      );
    }
  }

  Future<void> _editWish(WishEntry entry) async {
    final updated = await showWishEntrySheet(context, initial: entry);
    if (updated == null || !mounted) return;
    await runStoreAction(
      context,
      () => AppStore.instance.updateWish(updated),
      successMessage: '心愿已更新',
    );
  }

  Future<void> _decide(WishEntry entry, String status) async {
    await runStoreAction(
      context,
      () => AppStore.instance.decideWish(entry.id, status),
      successMessage: status == 'wanted'
          ? '已确认想要'
          : '已放弃「${entry.name}」，避免花费 ¥${formatMoney(entry.expectedPrice)}',
    );
  }

  Future<void> _extendCooling(WishEntry entry) async {
    final extended = entry.copyWith(
      createdAt: DateTime.now().toIso8601String(),
      coolingDays: 7,
      status: 'cooling',
    );
    await runStoreAction(
      context,
      () => AppStore.instance.updateWish(extended),
      successMessage: '已再冷静 7 天',
    );
  }
}

String _desireLabel(String value) {
  return switch (value) {
    'need' => '现在需要',
    'long-term' => '长期改善',
    'impulse' => '短暂冲动',
    _ => '未标注',
  };
}

class _WishDecisionOverview extends StatelessWidget {
  const _WishDecisionOverview({
    required this.wishes,
    required this.avoidedAmount,
  });

  final List<WishEntry> wishes;
  final double avoidedAmount;

  @override
  Widget build(BuildContext context) {
    final pending = wishes.where((entry) => entry.status == 'cooling').toList()
      ..sort((a, b) => a.remainingDays.compareTo(b.remainingDays));
    final decided = wishes.length - pending.length;
    final nearest = pending.isEmpty ? null : pending.first;
    final title = pending.isEmpty
        ? wishes.isEmpty
              ? '把想买的，先交给时间'
              : '每个心愿都已经有了答案'
        : '还有 ${pending.length} 个心愿等待决定';
    final detail = nearest == null
        ? wishes.isEmpty
              ? '记录一个心愿，让冷静期帮你分辨需要与冲动。'
              : '愿每一次放下与选择，都让生活更清楚。'
        : nearest.remainingDays == 0
        ? '「${nearest.name}」的冷静期已经结束，可以做出决定了。'
        : '最近的「${nearest.name}」还有 ${nearest.remainingDays} 天结束冷静期。';
    return GradientCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '未入匣',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Songti SC',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: MiniMetric(
                  label: '待决定',
                  value: '${pending.length}',
                  dark: true,
                ),
              ),
              Expanded(
                child: MiniMetric(label: '已决定', value: '$decided', dark: true),
              ),
              Expanded(
                child: MiniMetric(
                  label: '避免花费',
                  value: '¥${formatMoney(avoidedAmount, compact: true)}',
                  dark: true,
                ),
              ),
            ],
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
    required this.onWanted,
    required this.onAbandoned,
    required this.onExtend,
  });

  final WishEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onWanted;
  final VoidCallback onAbandoned;
  final VoidCallback onExtend;

  @override
  State<_WishCard> createState() => _WishCardState();
}

class _WishCardState extends State<_WishCard> {
  bool _revealEarlyDecision = false;

  WishEntry get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    final status = switch (entry.status) {
      'wanted' => ('确认想要', const Color(0xFF2E7568), const Color(0xFFE7F6F1)),
      'abandoned' => ('已放弃', const Color(0xFFC6657D), const Color(0xFFFAEDF2)),
      'achieved' => ('已达成', const Color(0xFF607FC7), const Color(0xFFEDF2FB)),
      _ => ('冷静中', const Color(0xFFC28B35), const Color(0xFFFBF3DF)),
    };
    return SoftCard(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.reason.isEmpty ? '还没有写下想要它的原因。' : entry.reason,
                  style: const TextStyle(color: appMuted, height: 1.6),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: MiniMetric(
                        label: '预计价格',
                        value: '¥${formatMoney(entry.expectedPrice)}',
                      ),
                    ),
                    Expanded(
                      child: MiniMetric(
                        label: '冷静期',
                        value: '${entry.coolingDays} 天',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (entry.desireType.isNotEmpty) ...[
                  Text(
                    '购买动机 · ${_desireLabel(entry.desireType)}',
                    style: const TextStyle(
                      color: appMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => widget.onEdit(),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('编辑'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => widget.onDelete(),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('删除心愿'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                        style: const TextStyle(
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
                  '${entry.categoryInfo.name} · 预计 ¥${formatMoney(entry.expectedPrice)}'
                  '${entry.desireType.isEmpty ? '' : ' · ${_desireLabel(entry.desireType)}'}',
                  style: const TextStyle(color: appMuted, fontSize: 11),
                ),
                if (entry.reason.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.reason.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF777269),
                      fontSize: 10,
                      height: 1.42,
                    ),
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
                      backgroundColor: const Color(0xFFF1EEE9),
                      color: const Color(0xFFC28B35),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '已冷静 ${entry.elapsedDays}/${entry.coolingDays} 天 · ${entry.remainingDays == 0 ? '可以决定了' : '还有 ${entry.remainingDays} 天决定'}',
                    style: const TextStyle(
                      color: Color(0xFF777269),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (entry.remainingDays == 0 || _revealEarlyDecision)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: widget.onWanted,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 35),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              '仍想要',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: widget.onAbandoned,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFAEDF2),
                              foregroundColor: const Color(0xFFC6657D),
                              minimumSize: const Size(0, 35),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              '放弃',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onExtend,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 35),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              '再冷静 7 天',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () =>
                              setState(() => _revealEarlyDecision = true),
                          child: const Text(
                            '提前决定',
                            style: TextStyle(fontSize: 10),
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

class WishlistEmptyState extends StatelessWidget {
  const WishlistEmptyState({
    super.key,
    required this.hasAnyWishes,
    required this.onAdd,
    required this.onShowAll,
  });

  final bool hasAnyWishes;
  final VoidCallback onAdd;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: hasAnyWishes ? '这个状态下还没有心愿' : '心愿匣还是空的',
      description: hasAnyWishes
          ? '当前筛选状态没有记录，可以查看全部心愿。'
          : '把想买的东西先放进来，让时间帮你判断。',
      icon: hasAnyWishes
          ? Icons.filter_alt_off_rounded
          : Icons.favorite_border_rounded,
      action: PrimaryButton(
        label: hasAnyWishes ? '查看全部心愿' : '记录一个心愿',
        icon: hasAnyWishes ? Icons.filter_alt_rounded : Icons.add_rounded,
        expanded: false,
        onPressed: hasAnyWishes ? onShowAll : onAdd,
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
  late String _desireType;

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
    _desireType = initial?.desireType ?? (initial == null ? 'need' : '');
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
    final keyboardInset = media.viewInsets.bottom;
    final availableHeight =
        media.size.height - keyboardInset - media.padding.top;
    final maxHeight = keyboardInset > 0
        ? math.min(520.0, math.max(220.0, availableHeight * 0.62))
        : math.min(680.0, media.size.height * 0.78);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          key: const Key('wish-form-sheet'),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0DCD5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.initial == null ? '记录一个心愿' : '编辑心愿',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '先把它留在这里，过几天再决定要不要带回家。',
                    style: TextStyle(color: appMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: '想要什么'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
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
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  BottomSelectField<String>(
                    label: '购买动机',
                    value: _desireType.isEmpty ? null : _desireType,
                    hint: '请选择',
                    options: const [
                      BottomSelectOption(value: 'need', label: '现在需要'),
                      BottomSelectOption(value: 'long-term', label: '长期改善'),
                      BottomSelectOption(value: 'impulse', label: '短暂冲动'),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _desireType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reason,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '为什么想要',
                      hintText: '写下真实用途，帮助未来的自己判断',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: '放入心愿匣',
                    onPressed: () {
                      final name = _name.text.trim();
                      if (name.isEmpty) {
                        showAppSnack(context, '请填写心愿名称');
                        return;
                      }
                      final price = double.tryParse(
                        _price.text.replaceAll(',', ''),
                      );
                      if (_price.text.trim().isNotEmpty &&
                          (price == null || price < 0)) {
                        showAppSnack(context, '请输入有效的预计价格');
                        return;
                      }
                      Navigator.pop(
                        context,
                        WishEntry(
                          id:
                              widget.initial?.id ??
                              'wish_${DateTime.now().microsecondsSinceEpoch}',
                          name: name,
                          category: _category,
                          expectedPrice: price ?? 0,
                          reason: _reason.text.trim(),
                          coolingDays: _coolingDays,
                          createdAt:
                              widget.initial?.createdAt ??
                              DateTime.now().toIso8601String(),
                          status: widget.initial?.status ?? 'cooling',
                          desireType: _desireType,
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
