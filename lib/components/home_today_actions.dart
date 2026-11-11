import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets.dart';

class HomeActionItem {
  const HomeActionItem({
    required this.label,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class HomeTodayActions extends StatelessWidget {
  const HomeTodayActions({super.key, required this.actions});

  final List<HomeActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            _ActionRow(action: actions[index]),
            if (index < actions.length - 1) const ContentDivider(indent: 66),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final HomeActionItem action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(action.icon, color: action.color, size: 19),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMutedColor,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB9B4AC),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
