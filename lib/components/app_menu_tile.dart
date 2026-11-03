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
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground ?? const Color(0xFFF2EFEA),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? const Color(0xFF8D8A82),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
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
                style: const TextStyle(color: Color(0xFF918C83), fontSize: 11),
              ),
            ),
          if (showChevron) ...[
            const SizedBox(width: 5),
            const Icon(
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
