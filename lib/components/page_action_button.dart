import 'package:flutter/material.dart';

class PageActionButton extends StatelessWidget {
  const PageActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.buttonKey,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? label,
      child: FilledButton.icon(
        key: buttonKey,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}
