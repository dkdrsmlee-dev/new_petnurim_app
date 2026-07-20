import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Figma `Toast box` (node-id: 698:12443) 스펙 기반의 공통 토스트 위젯.
///
/// 아래에서 위로 가볍게 올라오며 서서히 나타나는 애니메이션을 내포하고 있습니다.
class NurimToast extends StatelessWidget {
  final String message;
  final Animation<double> animation;

  const NurimToast({
    super.key,
    required this.message,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    // Slide from offset (0, 0.25) to (0, 0)
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    ));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slideAnimation,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.textStrong.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.4,
                  letterSpacing: -0.42,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
