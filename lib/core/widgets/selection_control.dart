import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

enum SelectionControlStyle { radio, checkbox }

class SelectionControl<T> extends StatelessWidget {
  const SelectionControl({
    super.key,
    required this.style,
    this.text,
    required this.value,
    this.groupValue,
    required this.onChanged,
    this.padding,
  });

  final SelectionControlStyle style;
  final String? text;

  // For radio, value is T, groupValue is T
  // For checkbox, value is bool, groupValue is ignored. We can just use value as bool.
  final T value;
  final T? groupValue;

  final ValueChanged<T?> onChanged;

  /// 항목 상하 패딩. 화면마다 디자인이 달라 덮어쓸 수 있게 열어 둔다
  /// (예: 멤버십 해지의 동의 체크는 패딩 없는 22 높이 한 줄).
  /// null 이면 기존 기본값(라디오 12 / 체크박스 10.5)을 쓴다.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bool isSelected;
    if (style == SelectionControlStyle.radio) {
      isSelected = value == groupValue;
    } else {
      isSelected = (value as bool?) ?? false;
    }

    final textColor = isSelected ? AppColors.textStrong : AppColors.textSecondary;
    final textWeight = isSelected ? FontWeight.w600 : FontWeight.w500;

    return InkWell(
      onTap: () {
        if (style == SelectionControlStyle.radio) {
          if (!isSelected) {
            onChanged(value);
          }
        } else {
          final nextVal = !((value as bool?) ?? false);
          onChanged(nextVal as T);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        // 피그마 Selection control: 라디오 항목은 상하 패딩 12 + 아이콘 21 = 45.
        // 체크박스(동의)는 별도 스펙이라 기존 값을 유지한다.
        padding: padding ??
            EdgeInsets.symmetric(
              vertical: style == SelectionControlStyle.radio ? 12 : 10.5,
            ),
        child: Row(
          // 피그마 Selection control 은 items-start 다. 한 줄일 때는 차이가
          // 없지만(체크박스 22 vs 줄상자 22.4), 좁은 화면에서 라벨이 두 줄로
          // 접히면 가운데 정렬은 아이콘이 글줄 사이에 뜬다.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(isSelected),
            if (text != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text!,
                  style: TextStyle(
                    // 피그마: 라디오 라벨 15, 체크박스 라벨 16
                    fontSize:
                        style == SelectionControlStyle.radio ? 15 : 16,
                    fontWeight: textWeight,
                    color: textColor,
                    height: 1.4,
                    // 디자인 tracking -0.66 이 빠져 있어 라벨이 디자인보다
                    // 넓게 잡히고, 그 때문에 좁은 화면에서 한 줄이 넘쳤다.
                    letterSpacing: -0.66,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(bool isSelected) {
    if (style == SelectionControlStyle.radio) {
      // 피그마 Radio(135:13259 미선택 / 60:3659 선택): 21x21 원에 테두리 6.3.
      // 선택·미선택 모두 안쪽이 비어 있는 도넛이고 링 색만 바뀐다.
      // Material 라디오는 선택 시 가운데가 채워져 모양이 달랐다. (검수 16행 ①)
      return Container(
        width: 21,
        height: 21,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: 6.3,
          ),
        ),
      );
    } else {
      // 피그마 Check box(135:13273 미선택 / 60:3695 선택): 22x22, radius 5.5.
      // 체크 표시는 항상 보이고 배경색만 #E8EBF1 -> #7F4FFF 로 바뀐다.
      // Material 체크박스는 미선택이 빈 사각형이라 모양이 달랐다. (검수 16행 ④)
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.borderLight,
          borderRadius: BorderRadius.circular(5.5),
        ),
        child: SvgPicture.asset(
          'assets/images/ic_check_22.svg',
          width: 22,
          height: 22,
        ),
      );
    }
  }
}
