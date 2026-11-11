import 'package:flutter/material.dart';

import '../../widgets.dart';

class WishlistEmptyState extends StatelessWidget {
  const WishlistEmptyState({
    super.key,
    required this.hasAnyWishes,
    required this.onAdd,
    required this.onShowAll,
    this.emptyTitle,
    this.emptyDescription,
    this.actionLabel,
  });

  final bool hasAnyWishes;
  final VoidCallback onAdd;
  final VoidCallback onShowAll;
  final String? emptyTitle;
  final String? emptyDescription;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: hasAnyWishes ? emptyTitle ?? '这个状态下还没有心愿' : '心愿匣还是空的',
      description: hasAnyWishes
          ? emptyDescription ?? '当前筛选状态没有记录，可以查看全部心愿。'
          : '把想买的东西先放进来，让时间帮你判断。',
      icon: hasAnyWishes
          ? Icons.filter_alt_off_rounded
          : Icons.favorite_border_rounded,
      action: PrimaryButton(
        label: hasAnyWishes ? actionLabel ?? '查看全部心愿' : '记录一个心愿',
        icon: hasAnyWishes ? Icons.filter_alt_rounded : Icons.add_rounded,
        expanded: false,
        onPressed: hasAnyWishes ? onShowAll : onAdd,
      ),
    );
  }
}
