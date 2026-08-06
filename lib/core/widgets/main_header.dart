import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/toast_util.dart';

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
            
            // Right Side Icons (Emergency, Bell, Profile)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emergency(전화/긴급) Icon (Figma Node: Icon/Emergency/24)
                // 고객센터 연결은 보류 — 현재는 준비 중 토스트만 노출.
                GestureDetector(
                  onTap: () => ToastUtil.show(context, '준비 중인 기능입니다.'),
                  behavior: HitTestBehavior.opaque,
                  child: const _EmergencyIcon(),
                ),
                const SizedBox(width: 16), // Gap between icons
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
                              color: AppColors.errorSoft, // Red badge color from Figma
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

/// Figma `Icon/Emergency/24` — 전화 아이콘 + 빨간 배지(흰 십자). 고객센터 진입용.
class _EmergencyIcon extends StatelessWidget {
  const _EmergencyIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          // 전화 아이콘(디자인 인셋 + 4.91° 회전, stroke #51565F)
          Positioned(
            left: 1.3,
            top: 2.3,
            right: 3.3,
            bottom: 2.3,
            child: Transform.rotate(
              angle: 4.91 * math.pi / 180,
              child: SvgPicture.asset('assets/images/icon_emergency.svg'),
            ),
          ),
          // 빨간 긴급 배지 + 흰 십자(+)
          Positioned(
            top: 1,
            right: 1,
            child: Container(
              width: 11,
              height: 11,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.errorSoft, // #FF5F5F
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 5, height: 1.8, color: Colors.white),
                  Container(width: 1.8, height: 5, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
