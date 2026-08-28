import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class NurimDatePickerBottomSheet extends StatefulWidget {
  final String title;
  final DateTime initialDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final ValueChanged<DateTime> onConfirm;

  const NurimDatePickerBottomSheet({
    super.key,
    required this.title,
    required this.initialDate,
    this.minimumDate,
    this.maximumDate,
    required this.onConfirm,
  });

  /// 날짜 선택 바텀 시트를 띄우고 선택된 날짜를 반환하는 스태틱 메소드
  static Future<DateTime?> show({
    required BuildContext context,
    required String title,
    required DateTime initialDate,
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return NurimDatePickerBottomSheet(
          title: title,
          initialDate: initialDate,
          minimumDate: minimumDate,
          maximumDate: maximumDate,
          onConfirm: (date) {
            Navigator.of(context).pop(date);
          },
        );
      },
    );
  }

  @override
  State<NurimDatePickerBottomSheet> createState() => _NurimDatePickerBottomSheetState();
}

class _NurimDatePickerBottomSheetState extends State<NurimDatePickerBottomSheet> {
  late int _tempYear;
  late int _tempMonth;
  late int _tempDay;

  late List<int> _years;
  final List<int> _months = List<int>.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tempYear = widget.initialDate.year;
    _tempMonth = widget.initialDate.month;
    _tempDay = widget.initialDate.day;

    final minYear = widget.minimumDate?.year ?? now.year - 24;
    final maxYear = widget.maximumDate?.year ?? now.year;
    _years = List<int>.generate(maxYear - minYear + 1, (i) => minYear + i);
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Figma `Day list` 휠 항목 스타일: 20 SemiBold, 선택 #30343C / 비선택 #D6DBE4.
  TextStyle _wheelStyle(bool selected) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.66,
        color: selected ? AppColors.textStrong : AppColors.border,
      );

  @override
  Widget build(BuildContext context) {
    final maxDays = _daysInMonth(_tempYear, _tempMonth);
    if (_tempDay > maxDays) _tempDay = maxDays;
    final days = List<int>.generate(maxDays, (i) => i + 1);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 헤더 영역 (타이틀 및 닫기 버튼)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    // Figma Popup title: 20 Bold, line-height 28(=1.4), ls -0.66
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      letterSpacing: -0.66,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  // Figma Icon/X/24
                  child: SvgPicture.asset(
                    'assets/images/ic_x_24.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ],
            ),
          ),
          // Figma Popup title/Calandar_select: 헤더 아래 구분선 없음
          // 2. CupertinoPicker 스크롤 휠 영역
          Stack(
            alignment: Alignment.center,
            children: [
              // 뒷배경에 피그마 명세 가로 라인 표시 (전체 너비를 횡단하는 구분선)
              IgnorePointer(
                child: Container(
                  height: 60, // Figma Day list: 행 높이 60
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight, width: 1.0),
                      bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    // 연도 휠
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _years.contains(_tempYear) ? _years.indexOf(_tempYear) : 0,
                        ),
                        itemExtent: 60, // Figma Day list
                        selectionOverlay: const SizedBox.shrink(), // 기본 회색 박스 제거
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _tempYear = _years[index];
                          });
                        },
                        children: _years.map((y) => Center(
                          child: Text('$y년', style: _wheelStyle(y == _tempYear)),
                        )).toList(),
                      ),
                    ),
                    // 월 휠
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _months.indexOf(_tempMonth),
                        ),
                        itemExtent: 60, // Figma Day list
                        selectionOverlay: const SizedBox.shrink(), // 기본 회색 박스 제거
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _tempMonth = _months[index];
                          });
                        },
                        children: _months.map((m) => Center(
                          child: Text(
                            '${m.toString().padLeft(2, '0')}월',
                            style: _wheelStyle(m == _tempMonth),
                          ),
                        )).toList(),
                      ),
                    ),
                    // 일 휠
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: days.contains(_tempDay) ? days.indexOf(_tempDay) : 0,
                        ),
                        itemExtent: 60, // Figma Day list
                        selectionOverlay: const SizedBox.shrink(), // 기본 회색 박스 제거
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _tempDay = days[index];
                          });
                        },
                        children: days.map((d) => Center(
                          child: Text(
                            '${d.toString().padLeft(2, '0')}일',
                            style: _wheelStyle(d == _tempDay),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3. 확인 버튼 영역
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirm(DateTime(_tempYear, _tempMonth, _tempDay));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
