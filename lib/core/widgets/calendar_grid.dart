import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final Widget Function(BuildContext context, DateTime date, bool isOutsideMonth) dayBuilder;

  const CalendarGrid({
    Key? key,
    required this.year,
    required this.month,
    required this.dayBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 해당 월의 1일
    final firstDayOfMonth = DateTime(year, month, 1);
    // 달력 시작일 (1일이 속한 주의 일요일)
    final startDayOffset = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final startDate = firstDayOfMonth.subtract(Duration(days: startDayOffset));
    
    // 달력의 총 날짜 셀 계산 (보통 6주 = 42일)
    // 5주(35일)로 끝나는 달도 있으므로 계산
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int totalCells = (startDayOffset + daysInMonth) > 35 ? 42 : 35;

    return Column(
      children: [
        // 요일 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
            return Expanded(
              child: SizedBox(
                height: 49,
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600, // SemiBold
                      color: AppColors.textSecondary, // text-color/secondary
                      letterSpacing: -0.48,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // 날짜 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final date = startDate.add(Duration(days: index));
            final isOutsideMonth = date.month != month;
            return dayBuilder(context, date, isOutsideMonth);
          },
        ),
      ],
    );
  }
}
