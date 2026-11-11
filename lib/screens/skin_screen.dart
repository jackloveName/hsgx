import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';
import '../widgets.dart';

class SkinScreen extends StatelessWidget {
  const SkinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final primary = scheme.primary;
        final systemSelected = AppStore.instance.skinIndex == -1;
        return PageFrame(
          title: '皮肤选择',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '三种收藏场景',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontFamily: 'Songti SC',
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '归青清润，花笺温柔，夜匣沉静。每套都包含完整的页面、卡片和控件配色。',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 20),
              SoftCard(
                onTap: () => runStoreAction(
                  context,
                  () => AppStore.instance.setSkin(-1),
                  successMessage: '已切换为跟随系统',
                ),
                borderColor: systemSelected
                    ? primary.withValues(alpha: 0.55)
                    : scheme.outlineVariant,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _SystemPreview(),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '跟随系统',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '浅色随系统使用归青，深色自动使用夜匣。',
                            style: TextStyle(fontSize: 11, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    _SelectedMark(selected: systemSelected, color: primary),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < appSkins.length; index++) ...[
                _SkinCard(
                  skin: appSkins[index],
                  selected: AppStore.instance.skinIndex == index,
                  onTap: () => runStoreAction(
                    context,
                    () => AppStore.instance.setSkin(index),
                    successMessage: '已切换为${appSkins[index].name}',
                  ),
                ),
                if (index != appSkins.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final AppSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${skin.name}皮肤',
      child: SoftCard(
        onTap: onTap,
        color: skin.surface,
        borderColor: selected
            ? skin.primary.withValues(alpha: 0.65)
            : skin.border,
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SkinPreview(skin: skin),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          skin.name,
                          style: TextStyle(
                            color: skin.text,
                            fontFamily: 'Songti SC',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: skin.primarySoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '当前',
                            style: TextStyle(
                              color: skin.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    skin.description,
                    style: TextStyle(
                      color: skin.muted,
                      fontSize: 11,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      _PaletteDot(color: skin.primary),
                      const SizedBox(width: 5),
                      _PaletteDot(color: skin.accent),
                      const SizedBox(width: 5),
                      _PaletteDot(color: skin.surfaceMuted),
                      const SizedBox(width: 8),
                      Text(
                        skin.brightness == Brightness.dark ? '深色' : '浅色',
                        style: TextStyle(
                          color: skin.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _SelectedMark(selected: selected, color: skin.primary),
          ],
        ),
      ),
    );
  }
}

class _SkinPreview extends StatelessWidget {
  const _SkinPreview({required this.skin});

  final AppSkin skin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 92,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: skin.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: skin.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: skin.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: skin.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: skin.primarySoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: skin.text.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 5),
                      FractionallySizedBox(
                        widthFactor: 0.62,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: skin.muted.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 17,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [skin.heroStart, skin.heroEnd],
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: skin.heroAccent,
                    size: 9,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: skin.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemPreview extends StatelessWidget {
  const _SystemPreview();

  @override
  Widget build(BuildContext context) {
    final light = appSkins.first;
    final dark = appSkins.last;
    return Container(
      width: 88,
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: ColoredBox(
              color: light.background,
              child: Center(
                child: Container(
                  width: 26,
                  height: 40,
                  decoration: BoxDecoration(
                    color: light.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: light.border),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: dark.background,
              child: Center(
                child: Container(
                  width: 26,
                  height: 40,
                  decoration: BoxDecoration(
                    color: dark.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dark.border),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteDot extends StatelessWidget {
  const _PaletteDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? color : context.appBorderColor),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 15, color: context.appSurfaceColor)
          : null,
    );
  }
}
