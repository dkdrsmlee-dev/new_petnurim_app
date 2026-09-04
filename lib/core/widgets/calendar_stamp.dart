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
                    // 피그마의 line-height 1.4 는 CSS 가 leading 을 위아래 균등 분배해
                    // 16 알약 안에서 세로 중앙에 놓인다. 반면 Flutter 는 leading 을
                    // 폰트 메트릭에 비례 배분해 글자가 아래로 3.5 쏠리고,
                    // leadingDistribution(TextStyle/TextHeightBehavior 양쪽) 으로도
                    // 교정되지 않는다. height 를 빼면 M3 기본값(bodyMedium 1.43)이
                    // 상속돼 마찬가지이므로, 폰트 고유 줄높이를 명시해 줄상자를
                    // 컨텐츠 박스(16 - 상하 패딩 1)와 일치시킨다. 그러면 CSS 와 같은
                    // baseline 이 된다. (Pretendard 12: ascent 11.43 + descent 2.57)
                    height: 14 / 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
