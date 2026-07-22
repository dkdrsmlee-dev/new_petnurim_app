import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'stamp_assets.dart';
import '../../../core/theme/app_colors.dart';

class RewardMilestoneStamp extends StatelessWidget {
  final String title;
  final int points;
  final bool isCompleted;

  const RewardMilestoneStamp({
    Key? key,
    required this.title,
    required this.points,
    required this.isCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 스탬프 원형 영역
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 배경 (완료/미완료)
              Positioned.fill(
                child: SvgPicture.string(
                  isCompleted ? StampAssets.bgSvgCompleted : StampAssets.bgSvgDisabled,
                  fit: BoxFit.contain,
                ),
              ),
              // 내부 발바닥 (완료/미완료)
              Positioned(
                top: isCompleted ? 24.19 : 28.5,
                child: SizedBox(
                  width: 44,
                  height: 33,
                  child: SvgPicture.string(
                    isCompleted ? StampAssets.pawSvgCompleted : StampAssets.pawSvgDisabled,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // 완료 텍스트 (완료 상태일 때만)
              if (isCompleted)
                Positioned(
                  top: 59,
                  left: 0,
                  right: 0,
                  child: Text(
                    '완료',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
              // 포인트 뱃지 (스탬프의 우측 상단 배치)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xFFF659E7) : AppColors.dot,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '${points}P',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700, // Bold
                      color: Colors.white,
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 하단 타이틀
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w600,
            color: isCompleted ? const Color(0xFF15354C) : const Color(0xFF4E8DBA),
            letterSpacing: -0.66,
          ),
        ),
      ],
    );
  }
}
