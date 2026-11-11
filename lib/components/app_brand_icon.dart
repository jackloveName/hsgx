import 'package:flutter/material.dart';

import '../models.dart';

class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({
    super.key,
    this.size = 72,
    this.padding = 4,
    this.radius,
    this.imageKey,
    this.backgroundColor,
    this.shadowColor,
    this.shadowBlur = 0,
    this.shadowOffset = Offset.zero,
    this.opacity = 1,
  });

  final double size;
  final double padding;
  final double? radius;
  final Key? imageKey;
  final Color? backgroundColor;
  final Color? shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final frameRadius = radius ?? size * 0.3;
    final imageRadius = (frameRadius - padding).clamp(0, frameRadius);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.appSurfaceColor,
        borderRadius: BorderRadius.circular(frameRadius),
        boxShadow: shadowBlur <= 0
            ? null
            : [
                BoxShadow(
                  color: shadowColor ?? Colors.black26,
                  blurRadius: shadowBlur,
                  offset: shadowOffset,
                ),
              ],
      ),
      child: Opacity(
        opacity: opacity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(imageRadius.toDouble()),
          child: Image.asset(
            'static/image/app-icon-192.webp',
            key: imageKey,
            fit: BoxFit.cover,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
          ),
        ),
      ),
    );
  }
}
