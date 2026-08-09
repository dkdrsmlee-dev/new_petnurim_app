import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';

/// 멤버십 해지 신청 완료 화면 (Figma 615:10503).
///
/// 구독 취소(`POST /memberships/{id}/cancel`) 성공 직후 표시한다. 해지 신청일과
/// 이용 종료일(현재 결제 기간 종료일)을 안내하고, 상단 X 또는 하단 "확인"으로 닫는다
/// (호출부가 구독 플로우를 걷어내고 마이펫 상세로 복귀시킨다).
class MembershipCancelCompleteScreen extends StatelessWidget {
  const MembershipCancelCompleteScreen({
    super.key,
    required this.applyDate,
    required this.endDate,
  });

  /// 해지 신청일(yyyy.MM.dd).
  final String applyDate;

  /// 이용 종료일(yyyy.MM.dd).
  final String endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '',
        showBackButton: false,
        showDivider: false,
        actions: [
          IconButton(
            tooltip: '닫기',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 24, color: AppColors.textStrong),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.check_rounded, size: 30, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '멤버십 해지 신청이 완료되었습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          letterSpacing: -0.66,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '이용 종료일까지\n혜택을 계속 이용할 수 있어요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.66,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.bgGray,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _row('해지 신청일', applyDate),
                            const SizedBox(height: 16),
                            _row('이용 종료일', endDate, emphasize: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.66,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 16,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.66,
            color: emphasize ? AppColors.textStrong : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
