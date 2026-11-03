import 'package:flutter/material.dart';

import '../app_store.dart';
import '../components/filter_pill_bar.dart';
import '../models.dart';
import '../widgets.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String _filter = 'all';

  static const _tabs = [
    ('all', '全部', appBlue, Color(0xFFEDF2FB)),
    ('cooling', '冷静中', Color(0xFFC28B35), Color(0xFFFBF3DF)),
    ('wanted', '确认想要', Color(0xFF2E7568), Color(0xFFE7F6F1)),
    ('achieved', '已达成', Color(0xFF607FC7), Color(0xFFEDF2FB)),
    ('abandoned', '已放弃', Color(0xFFC6657D), Color(0xFFFAEDF2)),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final entries = AppStore.instance.wishlist
            .where((entry) => _filter == 'all' || entry.status == _filter)
            .toList();
        return PageFrame(
          title: '心愿匣',
          action: IconButton.filledTonal(
            onPressed: _addWish,
            tooltip: '添加心愿',
            icon: const Icon(Icons.add_rounded),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GradientCard(
                colors: const [Color(0xFF62CDB5), Color(0xFF6C9FE8)],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: MiniMetric(
                        label: '避免花费',
                        value:
                            '¥${formatMoney(AppStore.instance.avoidedAmount)}',
                        dark: true,
                      ),
                    ),
                    Text(
                      '${AppStore.instance.wishlist.length} 个心愿',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
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
                      color: tab.$3,
                      backgroundColor: tab.$4,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (entries.isEmpty)
                EmptyState(
                  title: '心愿匣还是空的',
                  description: '把想买的东西先放进来，让时间帮你判断。',
                  icon: Icons.favorite_border_rounded,
                  action: PrimaryButton(
                    label: '记录一个心愿',
                    icon: Icons.add_rounded,
                    expanded: false,
                    onPressed: _addWish,
                  ),
                )
              else
                for (final entry in entries) ...[
                  _WishCard(
                    entry: entry,
                    onEdit: () => _editWish(entry),
                    onDelete: () => _delete(entry),
                    onWanted: () => _decide(entry, 'wanted'),
                    onAbandoned: () => _decide(entry, 'abandoned'),
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
    final entry = await showModalBottomSheet<WishEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddWishSheet(),
    );
    if (entry != null) {
      if (!mounted) return;
      await runStoreAction(
        context,
        () => AppStore.instance.addWish(entry),
        successMessage: '心愿已放入冷静期',
      );
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
    final updated = await showModalBottomSheet<WishEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddWishSheet(initial: entry),
    );
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
      successMessage: status == 'wanted' ? '已确认想要' : '已放弃购买',
    );
  }
}

class _WishCard extends StatelessWidget {
  const _WishCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    required this.onWanted,
    required this.onAbandoned,
  });

  final WishEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onWanted;
  final VoidCallback onAbandoned;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => onEdit(),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('编辑'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => onDelete(),
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
                  '${entry.categoryInfo.name} · 预计 ¥${formatMoney(entry.expectedPrice)}',
                  style: const TextStyle(color: appMuted, fontSize: 11),
                ),
                if (entry.status == 'cooling') ...[
                  const SizedBox(height: 8),
                  Text(
                    '已冷静 ${entry.elapsedDays}/${entry.coolingDays} 天 · ${entry.remainingDays == 0 ? '可以决定了' : '还有 ${entry.remainingDays} 天决定'}',
                    style: const TextStyle(
                      color: Color(0xFF777269),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: onWanted,
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
                          onPressed: onAbandoned,
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
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                autofocus: true,
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
                        if (value != null) setState(() => _category = value);
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
                  if (value != null) setState(() => _coolingDays = value);
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
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
