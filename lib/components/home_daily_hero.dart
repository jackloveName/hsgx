import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeDailyHero extends StatelessWidget {
  const HomeDailyHero({
    super.key,
    required this.item,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final InventoryItem? item;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 228),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.heroStart, tokens.heroEnd],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: tokens.heroStart.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              right: -58,
              top: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.045),
                  border: Border.all(
                    color: const Color(0xFFE5C98C).withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -74,
              bottom: -118,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE5C98C).withValues(alpha: 0.045),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 19, 18, 20),
              child: item == null
                  ? _EmptyHero(
                      title: title,
                      message: message,
                      actionLabel: actionLabel,
                      onAction: onAction,
                    )
                  : _ItemHero(
                      item: item!,
                      title: title,
                      message: message,
                      actionLabel: actionLabel,
                      onAction: onAction,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemHero extends StatelessWidget {
  const _ItemHero({
    required this.item,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final InventoryItem item;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '今日一物',
          style: TextStyle(
            color: Color(0xFFE8CC91),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.imagePath.trim().isEmpty) ...[
                    StatusPill(status: item.statusInfo, compact: true),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Songti SC',
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.62,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF5E8CC),
                      foregroundColor: const Color(0xFF294137),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_outward_rounded, size: 15),
                    label: Text(actionLabel),
                  ),
                ],
              ),
            ),
            if (item.imagePath.trim().isNotEmpty) ...[
              const SizedBox(width: 13),
              _HeroItemVisual(item: item),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeroItemVisual extends StatelessWidget {
  const _HeroItemVisual({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFE5C98C).withValues(alpha: 0.7),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ItemPhoto(item: item, height: 132, radius: 0),
            Positioned(
              left: 7,
              top: 7,
              child: StatusPill(status: item.statusInfo, compact: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              '今日一物',
              style: TextStyle(
                color: Color(0xFFE8CC91),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
            Spacer(),
            Text(
              '从第一件开始',
              style: TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 17),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Songti SC',
                      fontSize: 27,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.62,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 96,
              height: 112,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EFDF),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFFE5C98C).withValues(alpha: 0.7),
                ),
              ),
              child: Image.asset(itemCategories.last.asset),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: const [
            _StepPill(index: '01', label: '选一件常用物品'),
            _StepPill(index: '02', label: '拍照记录'),
            _StepPill(index: '03', label: '一周后回看'),
          ],
        ),
        const SizedBox(height: 17),
        FilledButton.icon(
          onPressed: onAction,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF5E8CC),
            foregroundColor: const Color(0xFF294137),
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 17),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.index, required this.label});

  final String index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            index,
            style: const TextStyle(
              color: Color(0xFFE8CC91),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
