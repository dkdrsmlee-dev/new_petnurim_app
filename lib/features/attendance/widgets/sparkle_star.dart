import 'package:flutter/material.dart';

class SparkleStar extends StatelessWidget {
  final double size;
  final Color color;

  const SparkleStar({
    Key? key,
    this.size = 12.0,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparkleStarPainter(color),
    );
  }
}

class _SparkleStarPainter extends CustomPainter {
  final Color color;

  _SparkleStarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Draw a 4-pointed sparkle star
    path.moveTo(cx, 0); // Top
    path.quadraticBezierTo(cx, cy, size.width, cy); // Top to Right
    path.quadraticBezierTo(cx, cy, cx, size.height); // Right to Bottom
    path.quadraticBezierTo(cx, cy, 0, cy); // Bottom to Left
    path.quadraticBezierTo(cx, cy, cx, 0); // Left to Top
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
