import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key, this.recovered = false, this.store});

  final bool recovered;
  final AppStore? store;

  AppStore get _store => store ?? AppStore.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final store = _store;
        final idleItems = store.items
            .where((item) => item.status == 'idle')
            .toList();
        final plannedItems = idleItems
            .where((item) => item.hasRecoveryPlan)
            .toList();
        final pendingItems = idleItems
            .where((item) => !item.hasRecoveryPlan)
            .toList();
        final recoveredItems = store.items
            .where((item) => item.status == 'processed')
            .toList();
        final recoveredValue = recoveredItems
            .where((item) => item.canAggregateInBaseCurrency)
            .fold<double>(0, (sum, item) => sum + item.cashRecoveredAmount);
        final saleCount = recoveredItems
            .where((item) => item.disposalMethod == '转卖')
            .length;
        final recycleCount = recoveredItems
            .where((item) => item.disposalMethod == '回收')
            .length;
        final giftCount = recoveredItems
            .where((item) => item.disposalMethod == '转赠')
            .length;
        final discardCount = recoveredItems
            .where((item) => item.disposalMethod == '丢弃')
            .length;
        final hasForeignCurrency = store.activeItems.any(
          (item) => !item.canAggregateInBaseCurrency,
        );

        return PageFrame(
          title: recovered ? '惜物记录' : '惜物计划',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: MiniMetric(
                        label: recovered ? '已转卖' : '待决定',
                        value: recovered
                            ? '$saleCount 件'
                            : '${pendingItems.length} 件',
                        dark: true,
                      ),
                    ),
                    Expanded(
                      child: MiniMetric(
                        label: recovered ? '已回收' : '计划中',
                        value: recovered
                            ? '$recycleCount 件'
                            : '${plannedItems.length} 件',
                        dark: true,
                      ),
                    ),
                    if (recovered)
                      Expanded(
                        child: MiniMetric(
                          label: '累计净回血',
                          value:
                              '¥${formatMoney(recoveredValue, compact: true)}',
                          dark: true,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasForeignCurrency) ...[
                const SizedBox(height: 8),
                const Text(
                  '金额统计仅合计人民币，外币物品仍保留在下方清单中',
                  style: TextStyle(color: appMuted, fontSize: 9),
                ),
              ],
              if (recovered && (giftCount > 0 || discardCount > 0)) ...[
                const SizedBox(height: 8),
                Text(
                  '另有转赠 $giftCount 件 · 丢弃 $discardCount 件，未计入回血金额',
                  style: const TextStyle(color: appMuted, fontSize: 9),
                ),
              ],
              if (recovered) ...[
                const SectionHeading(title: '处理记录'),
                if (recoveredItems.isEmpty)
                  const EmptyState(
                    title: '暂无处理记录',
                    description: '完成转卖、回收、转赠或丢弃后会出现在这里。',
                    icon: Icons.recycling_rounded,
                  )
                else
                  for (final item in recoveredItems)
                    _ProcessedRecoveryCard(item: item),
              ] else ...[
                if (plannedItems.isNotEmpty) ...[
                  const SectionHeading(title: '计划处理'),
                  for (final item in plannedItems)
                    _PlannedRecoveryCard(
                      item: item,
                      onEdit: () => _planRecovery(context, item),
                      onComplete: () => _completeRecovery(context, item),
                      onCancel: () => _cancelPlan(context, item),
                    ),
                ],
                const SectionHeading(title: '待决定'),
                if (pendingItems.isEmpty)
                  EmptyState(
                    title: idleItems.isEmpty ? '暂无闲置物品' : '闲置物品都已制定计划',
                    description: idleItems.isEmpty
                        ? '使用频率下降时，可以在物品详情中切换为闲置状态。'
                        : '可以继续完成已有计划，或等待新的闲置物品。',
                    icon: Icons.recycling_rounded,
                  )
                else
                  for (final item in pendingItems)
                    _PendingRecoveryCard(
                      item: item,
                      onPlan: () => _planRecovery(context, item),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _planRecovery(BuildContext context, InventoryItem item) async {
    final result = await showDialog<_RecoveryPlanResult>(
      context: context,
      builder: (_) => _RecoveryPlanDialog(item: item),
    );
    if (result == null || !context.mounted) return;
    await runStoreAction(
      context,
      () => _store.planRecovery(
        item.id,
        method: result.method,
        targetPrice: result.targetPrice,
        deadline: result.deadline,
        platform: result.platform,
        contact: result.contact,
        note: result.note,
      ),
      successMessage: '已制定${result.method}计划',
    );
  }

  Future<void> _cancelPlan(BuildContext context, InventoryItem item) async {
    final confirmed = await confirmAction(
      context,
      title: '取消惜物计划',
      message: '取消后「${item.name}」会回到待决定列表。',
      confirmLabel: '取消计划',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runStoreAction(
      context,
      () => _store.cancelRecoveryPlan(item.id),
      successMessage: '已取消回血计划',
    );
  }

  Future<void> _completeRecovery(
    BuildContext context,
    InventoryItem item,
  ) async {
    final result = await showDialog<_RecoveryResult>(
      context: context,
      builder: (_) => _RecoveryDialog(item: item),
    );
    if (result == null || !context.mounted) return;
    await runStoreAction(
      context,
      () => _store.changeStatus(
        item.id,
        'processed',
        disposalMethod: result.method,
        disposalDetail: result.detail,
        disposalPlatform: result.platform,
        disposalContact: result.contact,
        disposalPrice: result.price,
        disposalCost: result.cost,
        processDate: result.processDate,
      ),
      successMessage: result.price > 0
          ? '已记录${result.method}，净回血 '
                '${item.currencySymbol}${formatMoney(result.price - result.cost)}'
          : '已记录${result.method}',
    );
  }
}

class _PendingRecoveryCard extends StatelessWidget {
  const _PendingRecoveryCard({required this.item, required this.onPlan});

  final InventoryItem item;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: SoftCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ItemDetailScreen(itemId: item.id),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ItemVisual(item: item, size: 54, radius: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '购入价 ${item.currencySymbol}${formatMoney(item.purchasePrice)}'
                    ' · 参考回血 '
                    '${item.currencySymbol}${formatMoney(item.recoveryEstimateLow, compact: true)}'
                    '–${item.currencySymbol}${formatMoney(item.recoveryEstimateHigh, compact: true)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: appMuted, fontSize: 9),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              key: Key('recovery-plan-${item.id}'),
              onPressed: onPlan,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('制定计划', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannedRecoveryCard extends StatelessWidget {
  const _PlannedRecoveryCard({
    required this.item,
    required this.onEdit,
    required this.onComplete,
    required this.onCancel,
  });

  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Dismissible(
        key: Key('planned-recovery-${item.id}'),
        direction: DismissDirection.endToStart,
        background: const SizedBox.shrink(),
        secondaryBackground: _CancelPlanSwipeBackground(itemName: item.name),
        confirmDismiss: (_) {
          onCancel();
          return Future.value(false);
        },
        child: SoftCard(
          onTap: onEdit,
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ItemVisual(item: item, size: 52, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _RecoveryMethodBadge(
                          key: Key('recovery-method-${item.id}'),
                          method: item.recoveryMethod,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _PlanMetricChip(
                          key: Key('planned-purchase-${item.id}'),
                          text:
                              '购入价 ${item.currencySymbol}${formatMoney(item.purchasePrice)}',
                        ),
                        if (item.recoveryMethod == '转卖' ||
                            item.recoveryMethod == '回收')
                          _PlanMetricChip(
                            key: Key('planned-target-${item.id}'),
                            text:
                                '目标 ${item.currencySymbol}${formatMoney(item.recoveryTargetPrice)}',
                            emphasized: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onComplete,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('完成', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelPlanSwipeBackground extends StatelessWidget {
  const _CancelPlanSwipeBackground({required this.itemName});

  final String itemName;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Semantics(
      label: '取消 $itemName 的计划',
      button: true,
      child: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, color: error, size: 18),
            const SizedBox(width: 5),
            Text(
              '取消',
              style: TextStyle(
                color: error,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryMethodBadge extends StatelessWidget {
  const _RecoveryMethodBadge({super.key, required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: primary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PlanMetricChip extends StatelessWidget {
  const _PlanMetricChip({
    super.key,
    required this.text,
    this.emphasized = false,
  });

  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? primary.withValues(alpha: 0.09)
            : const Color(0xFFF5F2ED),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: emphasized ? primary : appMuted,
          fontSize: 9,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProcessedRecoveryCard extends StatelessWidget {
  const _ProcessedRecoveryCard({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: SoftCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ItemDetailScreen(itemId: item.id),
          ),
        ),
        child: Row(
          children: [
            ItemVisual(item: item, size: 66, radius: 17),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _processedSummary(item),
                    style: const TextStyle(color: appMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _processedSummary(InventoryItem item) {
  final dateOrPlatform = item.disposalPlatform.isEmpty
      ? item.processDate
      : item.disposalPlatform;
  return switch (item.disposalMethod) {
    '转卖' =>
      '转卖 · $dateOrPlatform · '
          '净回血 +${item.currencySymbol}${formatMoney(item.cashRecoveredAmount)}',
    '回收' =>
      '回收 · $dateOrPlatform · '
          '净回血 +${item.currencySymbol}${formatMoney(item.cashRecoveredAmount)}',
    '转赠' =>
      '转赠 · 接收人 ${item.disposalContact.isEmpty ? '--' : item.disposalContact}'
          ' · ${item.processDate}',
    '丢弃' => '丢弃 · ${item.processDate}',
    _ => '${item.disposalMethod} · ${item.processDate}',
  };
}

class _RecoveryPlanResult {
  const _RecoveryPlanResult({
    required this.method,
    required this.targetPrice,
    required this.deadline,
    required this.platform,
    required this.contact,
    required this.note,
  });

  final String method;
  final double targetPrice;
  final String deadline;
  final String platform;
  final String contact;
  final String note;
}

class _RecoveryResult {
  const _RecoveryResult({
    required this.method,
    required this.platform,
    required this.contact,
    required this.detail,
    required this.price,
    required this.cost,
    required this.processDate,
  });

  final String method;
  final String platform;
  final String contact;
  final String detail;
  final double price;
  final double cost;
  final String processDate;
}

class _RecoveryPlanDialog extends StatefulWidget {
  const _RecoveryPlanDialog({required this.item});

  final InventoryItem item;

  @override
  State<_RecoveryPlanDialog> createState() => _RecoveryPlanDialogState();
}

class _RecoveryPlanDialogState extends State<_RecoveryPlanDialog> {
  late String _method = widget.item.recoveryMethod.isEmpty
      ? '转卖'
      : widget.item.recoveryMethod;
  late final TextEditingController _targetPrice = TextEditingController(
    text: formatMoney(
      widget.item.recoveryTargetPrice > 0
          ? widget.item.recoveryTargetPrice
          : widget.item.currentTotal * 0.7,
    ),
  );
  late final TextEditingController _detail = TextEditingController(
    text: widget.item.recoveryPlatform.isNotEmpty
        ? widget.item.recoveryPlatform
        : widget.item.recoveryContact,
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.item.recoveryNote,
  );
  late String _deadline = widget.item.recoveryDeadline.isEmpty
      ? formatDate(DateTime.now().add(const Duration(days: 14)))
      : widget.item.recoveryDeadline;

  bool get _cashMethod => _method == '转卖' || _method == '回收';

  @override
  void dispose() {
    _targetPrice.dispose();
    _detail.dispose();
    _note.dispose();
    super.dispose();
  }

  void _selectMethod(String method) {
    setState(() {
      _method = method;
      _detail.clear();
      if (method == '转卖' || method == '回收') {
        _targetPrice.text = formatMoney(widget.item.currentTotal * 0.7);
      }
    });
  }

  Future<void> _chooseDeadline() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: parseDate(_deadline) ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      title: '计划完成日期',
      confirmLabel: '确定日期',
    );
    if (picked != null) setState(() => _deadline = formatDate(picked));
  }

  void _submit() {
    final detail = _detail.text.trim();
    final target = double.tryParse(_targetPrice.text.replaceAll(',', ''));
    if (_cashMethod && (target == null || target <= 0)) {
      showAppSnack(context, '请输入有效的目标回血金额');
      return;
    }
    if (_method != '丢弃' && detail.isEmpty) {
      showAppSnack(context, _method == '转赠' ? '请输入接收人' : '请输入平台名称');
      return;
    }
    Navigator.pop(
      context,
      _RecoveryPlanResult(
        method: _method,
        targetPrice: _cashMethod ? target! : 0,
        deadline: _deadline,
        platform: _cashMethod ? detail : '',
        contact: _method == '转赠' ? detail : '',
        note: _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.hasRecoveryPlan ? '调整回血计划' : '制定回血计划'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSelectField<String>(
                label: '处理方式',
                value: _method,
                options: const [
                  BottomSelectOption(value: '转卖', label: '转卖'),
                  BottomSelectOption(value: '回收', label: '回收'),
                  BottomSelectOption(value: '转赠', label: '转赠'),
                  BottomSelectOption(value: '丢弃', label: '丢弃'),
                ],
                onChanged: (value) {
                  if (value != null) _selectMethod(value);
                },
              ),
              if (_cashMethod) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _targetPrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: '目标回血金额',
                    prefixText: '${widget.item.currencySymbol} ',
                  ),
                ),
              ],
              if (_method != '丢弃') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _detail,
                  decoration: InputDecoration(
                    labelText: _method == '转赠' ? '接收人' : '计划平台',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              InkWell(
                onTap: _chooseDeadline,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: '计划完成日期'),
                  child: Text(_deadline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '计划备注（选填）',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.item.hasRecoveryPlan ? '保存计划' : '创建计划'),
        ),
      ],
    );
  }
}

class _RecoveryDialog extends StatefulWidget {
  const _RecoveryDialog({required this.item});

  final InventoryItem item;

  @override
  State<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<_RecoveryDialog> {
  late String _method = widget.item.recoveryMethod.isEmpty
      ? '转卖'
      : widget.item.recoveryMethod;
  late final TextEditingController _price = TextEditingController(
    text: formatMoney(
      widget.item.recoveryTargetPrice > 0
          ? widget.item.recoveryTargetPrice
          : widget.item.currentTotal * 0.7,
    ),
  );
  final _cost = TextEditingController(text: '0');
  late final TextEditingController _detail = TextEditingController(
    text: widget.item.recoveryPlatform.isNotEmpty
        ? widget.item.recoveryPlatform
        : widget.item.recoveryContact,
  );

  bool get _cashMethod => _method == '转卖' || _method == '回收';

  @override
  void dispose() {
    _price.dispose();
    _cost.dispose();
    _detail.dispose();
    super.dispose();
  }

  void _selectMethod(String method) {
    setState(() {
      _method = method;
      _detail.clear();
      if (method != '转卖' && method != '回收') {
        _price.text = '0';
        _cost.text = '0';
      }
    });
  }

  double get _priceValue =>
      double.tryParse(_price.text.replaceAll(',', '')) ?? 0;
  double get _costValue => double.tryParse(_cost.text.replaceAll(',', '')) ?? 0;

  void _submit() {
    final detail = _detail.text.trim();
    if (_cashMethod && _priceValue <= 0) {
      showAppSnack(context, '请输入有效成交金额');
      return;
    }
    if (_method != '丢弃' && detail.isEmpty) {
      showAppSnack(context, _method == '转赠' ? '请输入接收人' : '请输入平台名称');
      return;
    }
    Navigator.pop(
      context,
      _RecoveryResult(
        method: _method,
        platform: _cashMethod ? detail : '',
        contact: _method == '转赠' ? detail : '',
        detail: detail,
        price: _cashMethod ? _priceValue : 0,
        cost: _cashMethod ? _costValue.clamp(0, double.infinity) : 0,
        processDate: formatDate(DateTime.now()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final net = (_priceValue - _costValue).clamp(0, double.infinity);
    return AlertDialog(
      title: const Text('完成闲置处理'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BottomSelectField<String>(
                label: '处理方式',
                value: _method,
                options: const [
                  BottomSelectOption(value: '转卖', label: '转卖'),
                  BottomSelectOption(value: '回收', label: '回收'),
                  BottomSelectOption(value: '转赠', label: '转赠'),
                  BottomSelectOption(value: '丢弃', label: '丢弃'),
                ],
                onChanged: (value) {
                  if (value != null) _selectMethod(value);
                },
              ),
              if (_cashMethod) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: '成交金额',
                    prefixText: '${widget.item.currencySymbol} ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: '运费、手续费等成本',
                    prefixText: '${widget.item.currencySymbol} ',
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '净回血 ${widget.item.currencySymbol}${formatMoney(net)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              if (_method != '丢弃') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _detail,
                  decoration: InputDecoration(
                    labelText: _method == '转赠' ? '接收人' : '平台名称',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('完成处理')),
      ],
    );
  }
}
