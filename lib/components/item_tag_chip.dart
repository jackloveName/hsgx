import 'package:flutter/material.dart';

class ItemTagChip extends StatelessWidget {
  const ItemTagChip({
    super.key,
    required this.label,
    required this.index,
    this.onDeleted,
  });

  static const palette = [
    (Color(0xFFE7F6F1), Color(0xFF2E7568)),
    (Color(0xFFFBF3DF), Color(0xFF936B22)),
    (Color(0xFFEDF2FB), Color(0xFF526FAD)),
    (Color(0xFFFAEDF2), Color(0xFFB45C73)),
    (Color(0xFFF1EDFA), Color(0xFF705C9C)),
  ];

  final String label;
  final int index;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = palette[index % palette.length];
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final background = dark
        ? Color.alphaBlend(
            colors.$2.withValues(alpha: 0.2),
            scheme.surfaceContainerLowest,
          )
        : colors.$1;
    final foreground = dark
        ? Color.lerp(colors.$2, Colors.white, 0.38)!
        : colors.$2;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 4),
            Semantics(
              button: true,
              label: '删除标签 $label',
              onTap: onDeleted,
              excludeSemantics: true,
              child: Tooltip(
                message: '删除标签',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDeleted,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: foreground.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
