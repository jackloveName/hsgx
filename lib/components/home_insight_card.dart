import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';

class HomeInsightCard extends StatelessWidget {
  const HomeInsightCard({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.onTap,
  });

  final String type;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconData = switch (type) {
      'warranty' => Icons.event_available_outlined,
      'stock' => Icons.inventory_2_outlined,
      'idle' => Icons.recycling_rounded,
      'wishlist' => Icons.favorite_border_rounded,
      'ignored' => Icons.visibility_off_outlined,
      'positive' => Icons.auto_awesome_rounded,
      _ => Icons.add_circle_outline_rounded,
    };
    final label = switch (type) {
      'warranty' => '期限提醒',
      'stock' => '库存提醒',
      'idle' => '闲置提醒',
      'wishlist' => '心愿提醒',
      'ignored' => '使用提醒',
      _ => '今日洞察',
    };
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE8EE), Color(0xFFFFF2DD)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, color: const Color(0xFFC87972), size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: appPink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF777269),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFB9B4AC),
            size: 20,
          ),
        ],
      ),
    );
  }
}
