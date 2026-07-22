import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PopupHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showCloseButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onClosePressed;

  const PopupHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showCloseButton = true,
    this.onBackPressed,
    this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textStrong),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700, // Bold
          color: AppColors.textStrong,
          letterSpacing: -0.54,
          height: 1.4,
        ),
      ),
      actions: showCloseButton
          ? [
              IconButton(
                icon: const Icon(Icons.close, size: 24, color: AppColors.textStrong),
                onPressed: onClosePressed ?? () => Navigator.of(context).pop(),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
