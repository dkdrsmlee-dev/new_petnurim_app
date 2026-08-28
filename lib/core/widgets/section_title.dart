import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class NurimSectionTitle extends StatelessWidget {
  const NurimSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
    this.showAction = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool showAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final hasAction =
        showAction && actionLabel != null && actionLabel!.trim().isNotEmpty;

    return Padding(
      padding: padding,
      child: SizedBox(
        height: 22,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Figma Body/semibold/md
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.textMuted, // #51565F
                ),
              ),
            ),
            if (hasAction) ...[
              const SizedBox(width: 16),
              _SectionTitleAction(
                label: actionLabel!,
                onPressed: onActionPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitleAction extends StatelessWidget {
  const _SectionTitleAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15, // Figma Body/medium/sm
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: -0.66,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 2),
        // Figma Icon/ArrowRight/16
        SvgPicture.asset(
          'assets/images/ic_arrow_right_16.svg',
          width: 16,
          height: 16,
        ),
      ],
    );

    if (onPressed == null) {
      return child;
    }

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: child,
      ),
    );
  }
}
