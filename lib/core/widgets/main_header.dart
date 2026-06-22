import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_routes.dart';

class MainHeader extends StatelessWidget implements PreferredSizeWidget {
  const MainHeader({super.key, this.onTapProfile});

  final VoidCallback? onTapProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo (Figma Node: 로고 1)
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: 112,
              height: 24,
              fit: BoxFit.contain,
            ),
            
            // Right Side Icons (Bell and Profile)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bell Icon with notification dot (Figma Node: Icon/Bell/24)
                GestureDetector(
                  onTap: () => context.push(AppRoutes.notificationCenter),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SvgPicture.asset(
                          'assets/images/icon_bell.svg',
                          width: 24,
                          height: 24,
                        ),
                        Positioned(
                          top: 2,
                          right: 3,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5F5F), // Red badge color from Figma
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Gap between icons
                // Profile Icon (Figma Node: Profile24_Icon)
                GestureDetector(
                  onTap: onTapProfile,
                  child: SvgPicture.asset(
                    'assets/images/icon_profile.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(52);
}
