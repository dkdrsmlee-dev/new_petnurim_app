import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 반려동물 나이(1~[maxAge]살) 선택 공통 바텀시트.
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
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '나이',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: AppColors.textStrong,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: maxAge,
                itemBuilder: (context, index) {
                  final ageVal = index + 1;
                  final isSelected = selectedAge == ageVal;
                  return ListTile(
                    title: Text(
                      '$ageVal살',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? AppColors.primary : AppColors.textStrong,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onSelected(ageVal);
                    },
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
