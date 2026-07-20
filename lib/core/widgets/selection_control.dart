import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SelectionControlStyle { radio, checkbox }

class SelectionControl<T> extends StatelessWidget {
  const SelectionControl({
    super.key,
    required this.style,
    this.text,
    required this.value,
    this.groupValue,
    required this.onChanged,
  });

  final SelectionControlStyle style;
  final String? text;

  // For radio, value is T, groupValue is T
  // For checkbox, value is bool, groupValue is ignored. We can just use value as bool.
  final T value;
  final T? groupValue;

  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isSelected;
    if (style == SelectionControlStyle.radio) {
      isSelected = value == groupValue;
    } else {
      isSelected = (value as bool?) ?? false;
    }

    final textColor = isSelected ? AppColors.textStrong : AppColors.textSecondary;
    final textWeight = isSelected ? FontWeight.w600 : FontWeight.w500;

    return InkWell(
      onTap: () {
        if (style == SelectionControlStyle.radio) {
          if (!isSelected) {
            onChanged(value);
          }
        } else {
          final nextVal = !((value as bool?) ?? false);
          onChanged(nextVal as T);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIcon(isSelected),
            if (text != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: textWeight,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(bool isSelected) {
    if (style == SelectionControlStyle.radio) {
      return Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppColors.primary : AppColors.borderLight,
        size: 24,
      );
    } else {
      return Icon(
        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
        color: isSelected ? AppColors.primary : AppColors.borderLight,
        size: 24,
      );
    }
  }
}
