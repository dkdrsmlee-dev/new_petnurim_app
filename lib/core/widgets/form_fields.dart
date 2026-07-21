import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 폼 필드 라벨. 필수 항목이면 라벨 뒤에 빨강 dot을 표시한다.
///
/// 여러 마이펫 폼 화면에 인라인으로 중복돼 있던 라벨 패턴을 공통화한 위젯.
class NurimFieldLabel extends StatelessWidget {
  const NurimFieldLabel(this.text, {super.key, this.isRequired = false});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: -0.66,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 2),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

/// 두 개 이상 나란히 놓는 pill 형태의 선택 탭 버튼(성별, 중성화 등).
///
/// 보통 [Row] 안에서 [Expanded]로 감싸 사용한다.
class NurimSelectableTab extends StatelessWidget {
  const NurimSelectableTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primaryStrong : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 마이펫 폼 공통 [TextField] 데코레이션(hint + 둥근 보더 + 포커스 강조).
InputDecoration nurimInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Pretendard',
      fontSize: 16,
      color: AppColors.placeholder,
      letterSpacing: -0.66,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
