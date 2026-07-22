import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
class CalendarStamp extends StatelessWidget {
  final bool isAttended;
  final bool showReward;
  final bool showToday;
  final int rewardPoint;

  const CalendarStamp({
    Key? key,
    required this.isAttended,
    this.showReward = false,
    this.showToday = false,
    this.rewardPoint = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 49,
      height: 49,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 스탬프 아이콘 (출석 완료 시에만 표시하거나 비활성 표시)
          if (isAttended)
            SvgPicture.asset(
              'assets/images/banner/paw.svg',
              width: 24,
              height: 18,
            ),
          
          // 오늘 표시 (우측 상단 빨간 점)
          if (showToday)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.errorSoft, // var(--color/red/60)
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
          // 리워드 포인트 뱃지 (하단 중앙)
          if (showReward)
            Positioned(
              bottom: 0,
              child: Container(
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF659E7), // var(--color/pink/60)
                  borderRadius: BorderRadius.circular(9999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${rewardPoint}P',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600, // SemiBold
                    color: Colors.white,
                    letterSpacing: -0.66,
                    height: 1.4, // line-height 보정
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
