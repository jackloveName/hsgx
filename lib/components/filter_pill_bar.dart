import 'package:flutter/material.dart';

class FilterPillOption<T> {
  const FilterPillOption({
    required this.value,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final T value;
  final String label;
  final Color color;
  final Color backgroundColor;
}

class FilterPillBar<T> extends StatelessWidget {
  const FilterPillBar({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    this.height = 47,
    this.fontSize = 11,
  });

  final List<FilterPillOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final EdgeInsets padding;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final selected = option.value == value;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onChanged(option.value),
            showCheckmark: false,
            side: BorderSide.none,
            backgroundColor: const Color(0xFFF6F2ED),
            selectedColor: option.backgroundColor,
            label: Text(
              option.label,
              style: TextStyle(
                color: selected ? option.color : const Color(0xFF918C83),
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          );
        },
      ),
    );
  }
}
