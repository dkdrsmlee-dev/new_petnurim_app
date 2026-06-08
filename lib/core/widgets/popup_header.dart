import 'package:flutter/material.dart';

class PopupHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onClosePressed;

  const PopupHeader({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.onClosePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF30343C)),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w700, // Bold
          color: Color(0xFF30343C),
          letterSpacing: -0.54,
          height: 1.4,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.close, size: 24, color: Color(0xFF30343C)),
          onPressed: onClosePressed ?? () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
