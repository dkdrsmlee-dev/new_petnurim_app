import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NurimBottomActionBar extends StatelessWidget {
  const NurimBottomActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.primaryEnabled = true,
    this.secondaryEnabled = true,
    this.isLoading = false,
    // Figma Navi button: 상단 4 / 좌우 16. 하단 24는 Android SafeArea 보정용 여백.
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 24),
  });

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final bool primaryEnabled;
  final bool secondaryEnabled;
  final bool isLoading;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final hasSecondary = secondaryLabel != null && onSecondaryPressed != null;

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: padding,
        child: Row(
          children: [
            if (hasSecondary) ...[
              Expanded(
                child: _ActionButton.secondary(
                  label: secondaryLabel!,
                  enabled: secondaryEnabled && !isLoading,
                  onPressed: onSecondaryPressed,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: _ActionButton.primary(
                label: primaryLabel,
                enabled: primaryEnabled && !isLoading,
                loading: isLoading,
                onPressed: onPrimaryPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton.primary({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.loading = false,
  }) : backgroundColor = AppColors.primary,
       foregroundColor = Colors.white,
       disabledBackgroundColor = AppColors.borderLight,
       disabledForegroundColor = AppColors.placeholder,
       borderSide = BorderSide.none;

  const _ActionButton.secondary({
    required this.label,
    required this.enabled,
    required this.onPressed,
  }) : loading = false,
       backgroundColor = Colors.white,
       foregroundColor = AppColors.textMuted,
       disabledBackgroundColor = Colors.white,
       disabledForegroundColor = AppColors.placeholder,
       borderSide = const BorderSide(
         color: AppColors.border,
       );

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color disabledBackgroundColor;
  final Color disabledForegroundColor;
  final BorderSide borderSide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: disabledBackgroundColor,
          disabledForegroundColor: disabledForegroundColor,
          elevation: 0,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.66,
          ),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
