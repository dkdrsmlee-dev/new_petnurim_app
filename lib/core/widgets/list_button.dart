import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NurimListButton extends StatelessWidget {
  const NurimListButton({
    super.key,
    required this.title,
    this.onPressed,
    this.leading,
    this.showTrailingIcon = true,
    this.enabled = true,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool showTrailingIcon;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  static const Color _backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onPressed != null;

    return Material(
      color: _backgroundColor,
      child: InkWell(
        onTap: effectiveEnabled ? onPressed : null,
        child: Container(
          height: 56,
          padding: padding,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 16)],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: enabled ? AppColors.textMuted : AppColors.placeholder,
                  ),
                ),
              ),
              if (showTrailingIcon) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: enabled ? AppColors.textSecondary : AppColors.placeholder,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

