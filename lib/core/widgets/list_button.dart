import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                // Figma Icon/ArrowRight/24 (#909AA9), 비활성 시에만 색 교체
                SvgPicture.asset(
                  'assets/images/ic_arrow_right_24.svg',
                  width: 24,
                  height: 24,
                  colorFilter: enabled
                      ? null
                      : const ColorFilter.mode(
                          AppColors.placeholder,
                          BlendMode.srcIn,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

