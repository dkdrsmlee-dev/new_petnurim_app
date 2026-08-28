import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// 반려동물 나이(1~[maxAge]살) 선택 공통 바텀시트 (Figma 226:14092).
///
/// 마이펫 등록/수정 화면에 중복 구현돼 있던 나이 선택 시트를 공통화한 것.
/// 항목을 탭하면 시트를 닫은 뒤 [onSelected]에 선택한 나이를 전달한다.
Future<void> showAgePickerSheet(
  BuildContext context, {
  required int? selectedAge,
  required ValueChanged<int> onSelected,
  int maxAge = 30,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더: 제목 20 Bold + 닫기(Icon/X/24). 리스트와는 구분선 없이 16 간격.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), // Figma: 좌우 16
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '나이',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.66,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: SvgPicture.asset(
                      'assets/images/ic_x_24.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: maxAge,
                itemBuilder: (context, index) {
                  final ageVal = index + 1;
                  final isSelected = selectedAge == ageVal;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onSelected(ageVal);
                    },
                    child: Container(
                      height: 54,
                      // 헤더(좌우 16)와 좌측 정렬을 맞춘다.
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$ageVal살',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: -0.66,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          // 선택 항목만 보라 체크(Icon/Check/24). 텍스트 색은 동일.
                          if (isSelected)
                            SvgPicture.asset(
                              'assets/images/ic_check_24.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                AppColors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
