import 'package:flutter/material.dart';

import '../models.dart';

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({
    super.key,
    this.width = 42,
    this.height = 5,
    this.color,
  });

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? context.appBorderColor,
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}
