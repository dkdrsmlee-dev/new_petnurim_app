import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BullitText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final Color? bulletColor;

  const BullitText({
    super.key,
    required this.text,
    this.textStyle,
    this.bulletColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 텍스트(14px * 1.4 = 19.6px) 첫 줄과 수직 중앙 정렬을 위한 래퍼
        SizedBox(
          height: 20, 
          width: 10, // 여백 포함
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: bulletColor ?? AppColors.textTertiary, // var(--color/gray/90)
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: textStyle ??
                const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w400, // Regular
                  color: AppColors.textTertiary, // var(--color/gray/90)
                  letterSpacing: -0.66,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
