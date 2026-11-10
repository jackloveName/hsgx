import 'package:flutter/material.dart';

import '../app_store.dart';
import '../models.dart';

class LocalDataStatusBanner extends StatelessWidget {
  const LocalDataStatusBanner({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final store = AppStore.instance;
        final localIssue =
            store.loadError != null || store.persistenceWarning != null;
        if (!localIssue) {
          return const SizedBox.shrink();
        }

        final isError = store.loadError != null;
        final message = store.loadError ?? store.persistenceWarning!;
        final color = isError
            ? const Color(0xFFC6657D)
            : const Color(0xFFC28B35);
        return Padding(
          padding: margin,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: isError
                  ? const Color(0xFFFFF5F7)
                  : const Color(0xFFFFFAF0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.warning_amber_rounded : Icons.save_outlined,
                  color: color,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isError ? '本地数据状态异常' : '本地保存提示',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: appMuted,
                          fontSize: 9,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
