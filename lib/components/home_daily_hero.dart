import 'package:flutter/material.dart';

import '../domain/item_display.dart';
import '../models.dart';
import '../theme.dart';
import 'item_name_text.dart';

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
            if (item == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 19, 18, 20),
                child: _EmptyHero(
                  title: title,
                  message: message,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
              )
            else
              _ItemHero(
                item: item!,
                title: title,
                message: message,
                actionLabel: actionLabel,
                onAction: onAction,
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
    final tokens = AppThemeTokens.of(context);
    final recentUse = recentUseText(item);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;
        final titleStyle = TextStyle(
          color: Colors.white,
          fontFamily: 'Songti SC',
          fontSize: compact ? 25 : 28,
          height: 1.18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        );
        return SizedBox(
          height: compact ? 264 : 280,
          child: Stack(
            children: [
              const Positioned.fill(
                child: Image(
                  key: Key('home-daily-backdrop'),
                  image: AssetImage('static/image/daily-scene-backdrop.webp'),
                  fit: BoxFit.cover,
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x0D09110E),
                        Color(0x2409110E),
                        Color(0x7A09110E),
                      ],
                      stops: [0, 0.42, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _HeroStatusChip(status: item.statusInfo),
                        const Spacer(),
                        Text(
                          '今日一物',
                          style: TextStyle(
                            color: tokens.heroAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ItemNameText(name: title, style: titleStyle, maxLines: 2),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 11,
                      runSpacing: 4,
                      children: [
                        _HeroMetaText('相伴 ${item.ownedDays} 天'),
                        _HeroMetaText(
                          recentUse == null
                              ? '等待第一次使用'
                              : recentUse.replaceFirst('最近使用：', '上次使用 '),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.heroAccent,
                        foregroundColor: tokens.heroStart,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'PingFang SC',
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
            ],
          ),
        );
      },
    );
  }
}

class _HeroStatusChip extends StatelessWidget {
  const _HeroStatusChip({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final dot = Color.lerp(status.color, Colors.white, 0.32)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF09110E).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.17)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetaText extends StatelessWidget {
  const _HeroMetaText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.35),
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
    final tokens = AppThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '今日一物',
              style: TextStyle(
                color: tokens.heroAccent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
              ),
            ),
            const Spacer(),
            const Text(
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
                  color: tokens.heroAccent.withValues(alpha: 0.7),
                ),
              ),
              child: Image.asset(itemCategories.last.asset),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
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
              fontFamily: 'PingFang SC',
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
    final accent = AppThemeTokens.of(context).heroAccent;
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
            style: TextStyle(
              color: accent,
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
