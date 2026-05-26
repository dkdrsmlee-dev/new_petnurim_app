import 'package:flutter/material.dart';

/// 피그마 `Mypage name` 컴포넌트 스펙 기반의 프로필 위젯 (Node ID: 177:14283).
class NurimMypageName extends StatelessWidget {
  const NurimMypageName({
    super.key,
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    final firstName = name.isNotEmpty ? name[0] : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18, // 지름 36px
          backgroundColor: const Color(0xFF7F4FFF), // var(--color/violet/90, #7f4fff)
          child: Text(
            firstName,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w600, // SemiBold
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8), // Gap: 8px
        Text.rich(
          TextSpan(
            text: name,
            style: const TextStyle(
              fontWeight: FontWeight.w600, // SemiBold
              color: Color(0xFF30343C), // var(--color/gray/120, #30343c)
            ),
            children: const [
              TextSpan(
                text: '님',
                style: TextStyle(
                  fontWeight: FontWeight.w500, // Medium
                  color: Color(0xFF51565F), // var(--color/gray/100, #51565f)
                ),
              ),
              TextSpan(
                text: ' 반가워요 :)',
                style: TextStyle(
                  fontWeight: FontWeight.w500, // Medium
                  color: Color(0xFF51565F), // var(--color/gray/100, #51565f)
                ),
              ),
            ],
          ),
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            height: 1.4,
            letterSpacing: -0.66,
          ),
        ),
      ],
    );
  }
}
