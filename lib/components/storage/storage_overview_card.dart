import 'package:flutter/material.dart';

import '../../widgets.dart';

class StorageOverviewCard extends StatelessWidget {
  const StorageOverviewCard({
    super.key,
    required this.locationCount,
    required this.placedCount,
    required this.unassignedCount,
  });

  final int locationCount;
  final int placedCount;
  final int unassignedCount;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.fromLTRB(19, 17, 19, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '让每件东西都有归处',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Songti SC',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '按空间整理，也比按分类更容易找到。',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: MiniMetric(
                  key: const Key('storage-location-count'),
                  label: '归处',
                  value: '$locationCount',
                  dark: true,
                ),
              ),
              Expanded(
                child: MiniMetric(
                  key: const Key('storage-placed-count'),
                  label: '已安放',
                  value: '$placedCount',
                  dark: true,
                ),
              ),
              Expanded(
                child: MiniMetric(
                  key: const Key('storage-unassigned-count'),
                  label: '待安放',
                  value: '$unassignedCount',
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
