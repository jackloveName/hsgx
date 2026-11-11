import 'package:flutter/material.dart';

class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.iconBackground,
    this.value,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 13),
    this.titleColor,
    this.titleWeight = FontWeight.w600,
    this.iconSize = 18,
    this.iconBoxSize = 36,
    this.iconRadius = 11,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;
  final EdgeInsetsGeometry contentPadding;
  final Color? titleColor;
  final FontWeight titleWeight;
  final double iconSize;
  final double iconBoxSize;
  final double iconRadius;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final content = Padding(
      padding: contentPadding,
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color:
                  iconBackground ??
                  Color.lerp(
                    primary,
                    Theme.of(context).colorScheme.surface,
                    0.9,
                  ),
              borderRadius: BorderRadius.circular(iconRadius),
            ),
            child: Icon(icon, size: iconSize, color: iconColor ?? primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: titleWeight,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Color(0xFF918C83),
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null)
            SizedBox(
              width: 120,
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(color: Color(0xFF918C83), fontSize: 11),
              ),
            ),
          if (showChevron) ...[
            const SizedBox(width: 5),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFB9B4AC),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
