import 'package:flutter/material.dart';

/// 소셜 로그인 버튼 아래에 표시되는 "최근에 로그인 했어요" 말풍선 위젯.
///
/// 꼬리가 위를 향해 버튼과 연결되도록 [Column]으로 꼬리 → 본체 순서로 구성합니다.
class LastLoginBadge extends StatelessWidget {
  const LastLoginBadge({super.key});

  static const _label = '최근에 로그인 했어요';
  static const _badgeColor = Color(0xFF1F2937);
  static const _textColor = Colors.white;
  static const _tailHeight = 6.0;
  static const _tailWidth = 10.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 버튼을 향해 위로 솟은 삼각형 꼬리
        SizedBox(
          height: _tailHeight,
          width: double.infinity,
          child: CustomPaint(
            painter: _UpwardTailPainter(
              color: _badgeColor,
              tailWidth: _tailWidth,
            ),
          ),
        ),
        // 말풍선 본체
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _badgeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            _label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textColor,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// 말풍선 본체 위에 위로 향하는 삼각형 꼬리를 그리는 [CustomPainter].
class _UpwardTailPainter extends CustomPainter {
  const _UpwardTailPainter({required this.color, required this.tailWidth});

  final Color color;
  final double tailWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;

    // 위로 향하는 삼각형: 꼭짓점(위 중앙) → 오른쪽 밑 → 왼쪽 밑
    final path = Path()
      ..moveTo(centerX, 0)
      ..lineTo(centerX + tailWidth / 2, size.height)
      ..lineTo(centerX - tailWidth / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _UpwardTailPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.tailWidth != tailWidth;
}
