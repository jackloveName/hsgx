import 'package:flutter/material.dart';

import '../models.dart';

class HomeAssetSummary extends StatelessWidget {
  const HomeAssetSummary({
    super.key,
    required this.totalValue,
    required this.ownedDailyCost,
    required this.totalCount,
    required this.inUseCount,
    required this.monthUsageDays,
    required this.onStatusTap,
    this.foreignCurrencyItemCount = 0,
  });

  final double totalValue;
  final double ownedDailyCost;
  final int totalCount;
  final int inUseCount;
  final int monthUsageDays;
  final ValueChanged<String> onStatusTap;
  final int foreignCurrencyItemCount;

  @override
  Widget build(BuildContext context) {
    final usageRate = totalCount == 0 ? 0.0 : inUseCount / totalCount;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            Color.lerp(primary, Colors.white, 0.92)!,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: appBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42392D).withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '当前估值',
                      style: TextStyle(
                        color: appMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '¥${formatMoney(totalValue, compact: true)}',
                      style: const TextStyle(
                        color: appText,
                        fontFamily: 'Songti SC',
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (foreignCurrencyItemCount > 0)
                      const Text(
                        '人民币合计 · 外币物品未合并',
                        style: TextStyle(color: appMuted, fontSize: 8),
                      ),
                  ],
                ),
              ),
              Text(
                '拥有日均 ¥${formatMoney(ownedDailyCost, compact: true)}',
                style: const TextStyle(color: appMuted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0EBE4)),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusMetric(
                label: '匣中之物',
                value: '$totalCount',
                color: primary,
                onTap: () => onStatusTap('all'),
              ),
              _StatusMetric(
                label: '本月使用',
                value: '$monthUsageDays 天',
                color: primary,
                onTap: () => onStatusTap('all'),
              ),
              _StatusMetric(
                label: '使用率',
                value: '${(usageRate * 100).round()}%',
                color: primary,
                onTap: () => onStatusTap('inuse'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: appMuted, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: appText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
