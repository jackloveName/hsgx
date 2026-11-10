import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'components/stored_image.dart';
import 'models.dart';
import 'theme.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(scheme.primary, Colors.white, 0.9)!,
            Theme.of(context).scaffoldBackgroundColor,
            Color.lerp(scheme.secondary, Colors.white, 0.92)!,
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
      child: child,
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.showBack = true,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 32),
    this.maxContentWidth = 760,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final bool showBack;
  final EdgeInsets padding;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AppBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (showBack)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _RoundIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            tooltip: '返回',
                            onTap: () => Navigator.maybePop(context),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 54),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Songti SC',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (action != null)
                        Align(alignment: Alignment.centerRight, child: action),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final contentWidth = math
                        .min(
                          math.max(
                            0.0,
                            constraints.maxWidth - padding.horizontal,
                          ),
                          maxContentWidth,
                        )
                        .toDouble();
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: padding,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(width: contentWidth, child: child),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContentPane extends StatelessWidget {
  const ContentPane({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: math.min(constraints.maxWidth, maxWidth).toDouble(),
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 19, color: appText),
          ),
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.onLongPress,
    this.borderColor = appBorder,
    this.color = Colors.white,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color borderColor;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42392D).withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null && onLongPress == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
  });

  final Widget child;
  final List<Color>? colors;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final resolvedColors = colors ?? <Color>[tokens.heroStart, tokens.heroEnd];
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: resolvedColors,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: resolvedColors.first.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: content,
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.only(top: 26, bottom: 13),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [scheme.primary, scheme.secondary],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class CategoryImage extends StatelessWidget {
  const CategoryImage({
    super.key,
    required this.category,
    this.size = 54,
    this.backgroundColor,
  });

  final ItemCategory category;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: backgroundColor ?? category.softColor,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      child: Image.asset(category.asset, fit: BoxFit.contain),
    );
  }
}

class ItemVisual extends StatelessWidget {
  const ItemVisual({
    super.key,
    required this.item,
    this.size = 64,
    this.radius = 18,
  });

  final InventoryItem item;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = item.imagePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: item.categoryInfo.softColor,
        child: image.isNotEmpty
            ? _LocalOrAssetImage(
                path: image,
                fit: BoxFit.cover,
                fallbackAsset: item.categoryInfo.asset,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
              )
            : Padding(
                padding: EdgeInsets.all(size * 0.16),
                child: Image.asset(
                  item.categoryInfo.asset,
                  fit: BoxFit.contain,
                ),
              ),
      ),
    );
  }
}

class ItemPhoto extends StatelessWidget {
  const ItemPhoto({
    super.key,
    required this.item,
    required this.height,
    this.radius = 16,
    this.fit = BoxFit.cover,
  });

  final InventoryItem item;
  final double height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final image = item.imagePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ColoredBox(
          color: item.categoryInfo.softColor,
          child: image.isNotEmpty
              ? _LocalOrAssetImage(
                  path: image,
                  fit: fit,
                  fallbackAsset: item.categoryInfo.asset,
                  cacheWidth:
                      (MediaQuery.sizeOf(context).width *
                              MediaQuery.devicePixelRatioOf(context) *
                              0.55)
                          .round(),
                )
              : Padding(
                  padding: EdgeInsets.all(
                    math.min(28.0, height * 0.2).toDouble(),
                  ),
                  child: Image.asset(
                    item.categoryInfo.asset,
                    fit: BoxFit.contain,
                  ),
                ),
        ),
      ),
    );
  }
}

class _LocalOrAssetImage extends StatelessWidget {
  const _LocalOrAssetImage({
    required this.path,
    required this.fit,
    required this.fallbackAsset,
    required this.cacheWidth,
  });

  final String path;
  final BoxFit fit;
  final String fallbackAsset;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    return StoredImage(
      path: path,
      fit: fit,
      cacheWidth: cacheWidth,
      fallback: Image.asset(fallbackAsset, fit: BoxFit.contain),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.compact = false});

  final ItemStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          color: status.color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$label',
        style: const TextStyle(
          color: Color(0xFF756785),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inventory_2_outlined,
    this.action,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: double.infinity,
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Color.lerp(primary, Colors.white, 0.88),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: appMuted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class BottomSelectOption<T> {
  const BottomSelectOption({
    required this.value,
    required this.label,
    this.leading,
  });

  final T? value;
  final String label;
  final Widget? leading;
}

class BottomSelectField<T> extends StatelessWidget {
  const BottomSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint = '请选择',
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<BottomSelectOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String hint;
  final bool enabled;

  BottomSelectOption<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      value: selected?.label ?? hint,
      child: InkWell(
        onTap: enabled ? () => _showOptions(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(
            labelText: label,
            enabled: enabled,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? appMuted : appMuted.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              if (selected?.leading != null) ...[
                selected!.leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  selected?.label ?? hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected == null || !enabled ? appMuted : appText,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final chosen = await showModalBottomSheet<BottomSelectOption<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final primary = Theme.of(context).colorScheme.primary;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.68,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 11),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0DCD5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 17, 22, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: appMuted,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1EDE7)),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                    itemCount: options.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 54,
                      color: Color(0xFFF4F0EA),
                    ),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option.value == value;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          leading: option.leading,
                          title: Text(
                            option.label,
                            style: TextStyle(
                              color: isSelected ? primary : appText,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: primary,
                                  size: 20,
                                )
                              : null,
                          onTap: () => Navigator.pop<BottomSelectOption<T>>(
                            context,
                            option,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen != null) onChanged(chosen.value);
  }
}

class MiniMetric extends StatelessWidget {
  const MiniMetric({
    super.key,
    required this.label,
    required this.value,
    this.dark = false,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final bool dark;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: dark ? Colors.white70 : appMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: dark ? Colors.white : appText,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

OverlayEntry? _activeTopNotice;

void showAppSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final previous = _activeTopNotice;
  if (previous?.mounted ?? false) previous!.remove();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) => _TopAppNotice(
      message: message,
      onDismissed: () {
        if (_activeTopNotice == entry) _activeTopNotice = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _activeTopNotice = entry;
  overlay.insert(entry);
}

class _TopAppNotice extends StatefulWidget {
  const _TopAppNotice({required this.message, required this.onDismissed});

  final String message;
  final VoidCallback onDismissed;

  @override
  State<_TopAppNotice> createState() => _TopAppNoticeState();
}

class _TopAppNoticeState extends State<_TopAppNotice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Timer? _dismissTimer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _dismissTimer = Timer(const Duration(milliseconds: 2800), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SafeArea(
          bottom: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.28),
                  end: Offset.zero,
                ).animate(curved),
                child: FadeTransition(
                  opacity: curved,
                  child: Material(
                    key: const Key('top-app-notice'),
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(13, 11, 15, 11),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.98),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.14),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.11),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: scheme.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                widget.message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 12,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> runStoreAction(
  BuildContext context,
  Future<void> Function() action, {
  String? successMessage,
}) async {
  try {
    await action();
    if (context.mounted && successMessage != null) {
      showAppSnack(context, successMessage);
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      showAppSnack(context, error.toString().replaceFirst('Bad state: ', ''));
    }
    return false;
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确定',
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: destructive
                    ? const Color(0xFFC6657D)
                    : Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}

Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = '选择日期',
  String confirmLabel = '确定',
}) {
  var initial = initialDate;
  if (initial.isBefore(firstDate)) initial = firstDate;
  if (initial.isAfter(lastDate)) initial = lastDate;
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BottomDatePickerSheet(
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      confirmLabel: confirmLabel,
    ),
  );
}

class _BottomDatePickerSheet extends StatefulWidget {
  const _BottomDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    required this.confirmLabel,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final String confirmLabel;

  @override
  State<_BottomDatePickerSheet> createState() => _BottomDatePickerSheetState();
}

class _BottomDatePickerSheetState extends State<_BottomDatePickerSheet> {
  late DateTime _selectedDate = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0DCD5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatChineseDate(_selectedDate),
                      style: TextStyle(
                        color: primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: CalendarDatePicker(
                  initialDate: widget.initialDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  currentDate: DateTime.now(),
                  onDateChanged: (date) {
                    setState(() => _selectedDate = date);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: PrimaryButton(
                label: widget.confirmLabel,
                icon: Icons.check_rounded,
                onPressed: () => Navigator.pop(context, _selectedDate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatChineseDate(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${date.year}年${date.month}月${date.day}日 '
        '星期${weekdays[date.weekday - 1]}';
  }
}
