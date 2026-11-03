import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';

class HomeAssetSummary extends StatelessWidget {
  const HomeAssetSummary({
    super.key,
    required this.totalValue,
    required this.ownedDailyCost,
    required this.idleValue,
    required this.totalCount,
    required this.inUseCount,
    required this.idleCount,
    required this.isGuest,
    required this.onStatusTap,
    required this.onAccountTap,
  });

  final double totalValue;
  final double ownedDailyCost;
  final double idleValue;
  final int totalCount;
  final int inUseCount;
  final int idleCount;
  final bool isGuest;
  final ValueChanged<String> onStatusTap;
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: const [Color(0xFF4FB79F), Color(0xFF6C99E4)],
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '当前估值资产',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              if (!isGuest)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onAccountTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_done_outlined,
                            color: Colors.white70,
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            '云端同步',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '¥${formatMoney(totalValue)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            idleValue > 0
                ? '闲置资产 ¥${formatMoney(idleValue, compact: true)} · '
                      '拥有日均 ¥${formatMoney(ownedDailyCost)}'
                : '拥有日均 ¥${formatMoney(ownedDailyCost)}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusMetric(
                label: '全部物品',
                value: totalCount,
                color: const Color(0xFF9BC9FF),
                onTap: () => onStatusTap('all'),
              ),
              _StatusMetric(
                label: '使用中',
                value: inUseCount,
                color: const Color(0xFFA8EFE1),
                onTap: () => onStatusTap('inuse'),
              ),
              _StatusMetric(
                label: '闲置',
                value: idleCount,
                color: const Color(0xFFFFDF9A),
                onTap: () => onStatusTap('idle'),
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
  final int value;
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
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(width: 5),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
