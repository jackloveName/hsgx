import 'package:flutter/material.dart';

import '../models.dart';

class GuestPageBanner extends StatelessWidget {
  const GuestPageBanner({
    super.key,
    required this.subtitle,
    required this.remainingAdds,
    required this.onLogin,
    this.margin = EdgeInsets.zero,
  });

  final String subtitle;
  final int remainingAdds;
  final VoidCallback onLogin;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final remaining = remainingAdds.clamp(0, 3);
    return Padding(
      padding: margin,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: context.appSurfaceColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: primary.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.cloud_off_rounded, color: primary, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本机游客',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appMutedColor, fontSize: 9),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (var index = 0; index < 3; index++) ...[
                  Container(
                    width: index < remaining ? 7 : 5,
                    height: index < remaining ? 20 : 12,
                    decoration: BoxDecoration(
                      color: index < remaining
                          ? primary
                          : context.appBorderColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  if (index < 2) const SizedBox(width: 4),
                ],
              ],
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                foregroundColor: primary,
                textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              child: Text('登录继续'),
            ),
          ],
        ),
      ),
    );
  }
}
