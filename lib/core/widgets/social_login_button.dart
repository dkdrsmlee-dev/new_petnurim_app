import 'package:flutter/material.dart';
import 'package:new_petnurim_app/features/auth/domain/social_provider.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.enabled,
    required this.pending,
    required this.onPressed,
  });

  final SocialProvider provider;
  final bool enabled;
  final bool pending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = SocialLoginButtonColors.fromProvider(provider);
    final label = pending
        ? '${provider.label} 연결 중'
        : '${provider.label}로 시작하기';

    return SizedBox(
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          disabledBackgroundColor: colors.background.withValues(alpha: 0.45),
          disabledForegroundColor: colors.foreground.withValues(alpha: 0.58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        onPressed: enabled ? onPressed : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.66,
                ),
              ),
            ),
            Positioned(
              left: 16,
              child: pending
                  ? SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.foreground,
                      ),
                    )
                  : SizedBox.square(
                      dimension: 24,
                      child: CustomPaint(
                        painter: provider == SocialProvider.kakao
                            ? KakaoLogoPainter(color: colors.foreground)
                            : NaverLogoPainter(color: colors.foreground),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class KakaoLogoPainter extends CustomPainter {
  final Color color;
  const KakaoLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final scaleX = size.width / 20.0;
    final scaleY = size.height / 18.7634;

    path.moveTo(10.0028 * scaleX, 0 * scaleY);
    path.cubicTo(
      4.47902 * scaleX, 0 * scaleY,
      0 * scaleX, 3.47874 * scaleY,
      0 * scaleX, 7.76327 * scaleY,
    );
    path.cubicTo(
      0 * scaleX, 10.4307 * scaleY,
      1.73382 * scaleX, 12.7813 * scaleY,
      4.36788 * scaleX, 14.1817 * scaleY,
    );
    path.lineTo(3.25646 * scaleX, 18.2551 * scaleY);
    path.cubicTo(
      3.15643 * scaleX, 18.6163 * scaleY,
      3.56766 * scaleX, 18.8997 * scaleY,
      3.88441 * scaleX, 18.6941 * scaleY,
    );
    path.lineTo(8.74687 * scaleX, 15.4654 * scaleY);
    path.cubicTo(
      9.1581 * scaleX, 15.5043 * scaleY,
      9.57488 * scaleX, 15.5265 * scaleY,
      9.99722 * scaleX, 15.5265 * scaleY,
    );
    path.cubicTo(
      15.521 * scaleX, 15.5265 * scaleY,
      20 * scaleX, 12.0478 * scaleY,
      20 * scaleX, 7.76327 * scaleY,
    );
    path.cubicTo(
      20 * scaleX, 3.47874 * scaleY,
      15.5265 * scaleX, 0 * scaleY,
      10.0028 * scaleX, 0 * scaleY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NaverLogoPainter extends CustomPainter {
  final Color color;
  const NaverLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final scaleX = size.width / 16.1333;
    final scaleY = size.height / 16.0;

    path.moveTo(10.9467 * scaleX, 8.56 * scaleY);
    path.lineTo(4.96 * scaleX, 0 * scaleY);
    path.lineTo(0 * scaleX, 0 * scaleY);
    path.lineTo(0 * scaleX, 16.0 * scaleY);
    path.lineTo(5.2 * scaleX, 16.0 * scaleY);
    path.lineTo(5.2 * scaleX, 7.44 * scaleY);
    path.lineTo(11.1733 * scaleX, 16.0 * scaleY);
    path.lineTo(16.1333 * scaleX, 16.0 * scaleY);
    path.lineTo(16.1333 * scaleX, 0 * scaleY);
    path.lineTo(10.9467 * scaleX, 0 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SocialLoginButtonColors {
  const SocialLoginButtonColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  factory SocialLoginButtonColors.fromProvider(SocialProvider provider) {
    switch (provider) {
      case SocialProvider.kakao:
        return const SocialLoginButtonColors(
          background: Color(0xFFFEE500),
          foreground: Color(0xFF111827),
        );
      case SocialProvider.naver:
        return const SocialLoginButtonColors(
          background: Color(0xFF03C75A),
          foreground: Colors.white,
        );
    }
  }
}
