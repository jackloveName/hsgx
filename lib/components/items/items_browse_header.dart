import 'package:flutter/material.dart';

import '../../domain/items_browse.dart';
import '../../models.dart';
import '../../theme.dart';

class ItemsBrowseHeader extends StatelessWidget {
  const ItemsBrowseHeader({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  final ItemsBrowseMode mode;
  final ValueChanged<ItemsBrowseMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 7, 20, 11),
      child: _BrowseModeBar(value: mode, onChanged: onModeChanged),
    );
  }
}

class _BrowseModeBar extends StatelessWidget {
  const _BrowseModeBar({required this.value, required this.onChanged});

  final ItemsBrowseMode value;
  final ValueChanged<ItemsBrowseMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final softPrimary = AppThemeTokens.of(context).softPrimary;
    const icons = {
      ItemsBrowseMode.gallery: Icons.dashboard_customize_outlined,
      ItemsBrowseMode.ledger: Icons.view_agenda_outlined,
      ItemsBrowseMode.location: Icons.shelves,
    };
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.appSurfaceColor.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Row(
        children: [
          for (final mode in ItemsBrowseMode.values)
            Expanded(
              child: InkWell(
                key: Key('items-view-${mode.iconName}'),
                onTap: () => onChanged(mode),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: mode == value ? softPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[mode],
                        size: 15,
                        color: mode == value ? primary : context.appMutedColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        mode.label,
                        style: TextStyle(
                          color: mode == value
                              ? primary
                              : context.appMutedColor,
                          fontSize: 9,
                          fontWeight: mode == value
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
