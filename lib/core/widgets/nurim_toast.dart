import 'package:flutter/material.dart';

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
              // Figma: 좌우 16 여백(= 343 폭), 안쪽 패딩 16 균일
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x99000000), // Figma scrim/60 = rgba(0,0,0,0.6)
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500, // Body/medium/md
                  color: Colors.white,
                  height: 1.4,
                  letterSpacing: -0.66,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
