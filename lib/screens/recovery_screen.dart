import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets.dart';
import 'item_detail_screen.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key, this.recovered = false});

  final bool recovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final idleItems = AppStore.instance.items
            .where((item) => item.status == 'idle')
            .toList();
        final recoveredItems = AppStore.instance.items
            .where((item) => item.status == 'processed')
            .toList();
        final displayItems = recovered ? recoveredItems : idleItems;
        final idleValue = idleItems.fold<double>(
          0,
          (sum, item) => sum + item.currentTotal,
        );
        final recoveredValue = recoveredItems.fold<double>(
          0,
          (sum, item) => sum + item.disposalPrice,
        );
        final saleCount = recoveredItems
            .where((item) => item.disposalMethod == '转卖')
            .length;
        final recycleCount = recoveredItems
            .where((item) => item.disposalMethod == '回收')
            .length;
        return PageFrame(
          title: recovered ? '已回血物品' : '闲置回血计划',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientCard(
                colors: const [Color(0xFFE4B15C), Color(0xFFE7849A)],
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: MiniMetric(
                        label: recovered ? '已转卖' : '闲置资产',
                        value: recovered
                            ? '$saleCount 件'
                            : '¥${formatMoney(idleValue)}',
                        dark: true,
                      ),
                    ),
                    Expanded(
                      child: MiniMetric(
                        label: recovered ? '已回收' : '预计可回收',
                        value: recovered
                            ? '$recycleCount 件'
                            : '¥${formatMoney(idleValue * 0.7)}',
                        dark: true,
                      ),
                    ),
                    Expanded(
                      child: MiniMetric(
                        label: recovered ? '累计回血' : '闲置物品',
                        value: recovered
                            ? '¥${formatMoney(recoveredValue)}'
                            : '${idleItems.length} 件',
                        dark: true,
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeading(title: recovered ? '回血记录' : '待处理物品'),
              if (displayItems.isEmpty)
                EmptyState(
                  title: recovered ? '暂无已回血物品' : '暂无闲置物品',
                  description: recovered
                      ? '完成转卖、回收或转赠后会出现在这里。'
                      : '使用频率下降时，可以在物品详情中切换为闲置状态。',
                  icon: Icons.recycling_rounded,
                )
              else
                for (final item in displayItems) ...[
                  SoftCard(
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
                                recovered
                                    ? '${item.disposalMethod} · '
                                          '${item.disposalPlatform.isEmpty ? item.processDate : item.disposalPlatform} · '
                                          '+${item.currencySymbol}${formatMoney(item.disposalPrice)}'
                                    : '闲置 ${item.idleDays} 天 · 当前估值 '
                                          '${item.currencySymbol}${formatMoney(item.currentTotal)}',
                                style: const TextStyle(
                                  color: appMuted,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 9),
                              if (!recovered)
                                FilledButton.tonal(
                                  onPressed: () =>
                                      _markProcessed(context, item),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    '记录回血',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _markProcessed(BuildContext context, InventoryItem item) async {
    final result =
        await showDialog<
          ({
            String method,
            String platform,
            String contact,
            double price,
            String processDate,
          })
        >(
          context: context,
          builder: (_) => _RecoveryDialog(item: item),
        );
    if (result == null) return;
    if (!context.mounted) return;
    await runStoreAction(
      context,
      () => AppStore.instance.changeStatus(
        item.id,
        'processed',
        disposalMethod: result.method,
        disposalDetail: result.contact,
        disposalPlatform: result.platform,
        disposalContact: result.contact,
        disposalPrice: result.price,
        processDate: result.processDate,
      ),
      successMessage:
          '已记录${result.method}，回血 '
          '${item.currencySymbol}${formatMoney(result.price)}',
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
  String _method = '转卖';
  late final TextEditingController _price = TextEditingController(
    text: formatMoney(widget.item.currentValue * 0.7),
  );
  final _detail = TextEditingController();

  @override
  void dispose() {
    _price.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('记录回血结果'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 15),
            BottomSelectField<String>(
              label: '处理方式',
              value: _method,
              options: const [
                BottomSelectOption(value: '转卖', label: '转卖'),
                BottomSelectOption(value: '转赠', label: '转赠'),
                BottomSelectOption(value: '回收', label: '回收'),
                BottomSelectOption(value: '丢弃', label: '丢弃'),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _method = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '实际回血金额')
                  .copyWith(prefixText: '${widget.item.currencySymbol} '),
            ),
            if (_method != '丢弃') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _detail,
                decoration: InputDecoration(
                  labelText: switch (_method) {
                    '转赠' => '接收人',
                    '回收' => '回收平台',
                    _ => '转卖平台',
                  },
                  hintText: '选填',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final price = double.tryParse(_price.text.replaceAll(',', ''));
            if (price == null || price < 0) {
              showAppSnack(context, '请输入有效的回血金额');
              return;
            }
            Navigator.pop(context, (
              method: _method,
              platform: _method == '转卖' || _method == '回收'
                  ? _detail.text.trim()
                  : '',
              contact: _method == '转卖' || _method == '转赠'
                  ? _detail.text.trim()
                  : '',
              price: price,
              processDate: formatDate(DateTime.now()),
            ));
          },
          child: const Text('完成处理'),
        ),
      ],
    );
  }
}
