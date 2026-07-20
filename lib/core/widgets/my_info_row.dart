import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Figma `My_info` 컴포넌트 스펙 기반의 단일 행 위젯.
///
/// 좌측에 라벨 및 정보 텍스트(주/부 텍스트), 우측에 아웃라인 형태의 액션 버튼을 배치합니다.
/// 하단 경계선(색상: `#E8EBF1`)을 그릴 수 있는 옵션을 제공합니다.
class NurimMyInfoRow extends StatelessWidget {
  const NurimMyInfoRow({
    super.key,
    required this.labelText,
    required this.primaryValue,
    this.secondaryValue,
    this.actionLabel = '관리',
    this.showActionButton = true,
    this.onActionPressed,
    this.showDivider = true,
    this.padding = const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
  });

  /// 행의 주 라벨 (예: "내 정보", "결제 수단")
  final String labelText;

  /// 주요 값 텍스트 (예: 이메일 주소)
  final String primaryValue;

  /// 보조 값 텍스트 (예: "(카카오)", "삼성카드(12**)")
  final String? secondaryValue;

  /// 액션 버튼의 라벨 (예: "관리", "변경")
  final String actionLabel;

  /// 액션 버튼 표시 여부 (기본값: true)
  final bool showActionButton;

  /// 액션 버튼 클릭 시 콜백
  final VoidCallback? onActionPressed;

  /// 하단 경계선 표시 여부 (기본값: true)
  final bool showDivider;

  /// 위젯 바깥쪽 패딩 (기본값: 피그마 스펙 pt-[16px] px-[16px])
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 16.0, // Figma: pb-[16px]
        ),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(
                    color: AppColors.borderLight, // Figma: var(--line/soft, #e8ebf1)
                    width: 1.0,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 정보 텍스트 영역
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 라벨
                  Text(
                    labelText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16.0, // Figma: text-[16px]
                      fontWeight: FontWeight.w600, // SemiBold
                      height: 1.4,
                      letterSpacing: -0.66,
                      color: AppColors.textMuted, // var(--text-color/primary, #51565f)
                    ),
                  ),
                  const SizedBox(height: 8.0), // Figma: gap-[8px]
                  // 값 영역
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          primaryValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15.0, // Figma: text-[15px]
                            fontWeight: FontWeight.w500, // Medium
                            height: 1.4,
                            letterSpacing: -0.66,
                            color: AppColors.textSecondary, // var(--text-color/secondary, #87909e)
                          ),
                        ),
                      ),
                      if (secondaryValue != null && secondaryValue!.isNotEmpty) ...[
                        const SizedBox(width: 4.0),
                        Text(
                          secondaryValue!,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15.0, // Figma: text-[15px]
                            fontWeight: FontWeight.w500, // Medium
                            height: 1.4,
                            letterSpacing: -0.66,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 액션 버튼 영역
            if (showActionButton) ...[
              const SizedBox(width: 12.0),
              GestureDetector(
                onTap: onActionPressed,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 32.0, // Figma: h-[32px]
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, // Figma: px-[12px]
                    vertical: 6.0, // Figma: py-[6px]
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0), // Figma: rounded-[8px]
                    border: Border.all(
                      color: AppColors.border, // Figma: var(--line/default, #d6dbe4)
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14.0, // Figma: text-[14px]
                      fontWeight: FontWeight.w600, // SemiBold
                      height: 1.4,
                      letterSpacing: -0.66,
                      color: AppColors.textMuted, // var(--color/gray/100, #51565f)
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
