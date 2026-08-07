import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/widgets/page_header.dart';
import '../data/membership_repository.dart';
import '../domain/membership_models.dart';

/// 멤버십 구독 완료 화면 (USR-PAY-018, Figma 289:9512).
///
/// 카드 등록(`POST /memberships`) 성공 직후 표시한다. 전달받은 [membershipId]로
/// **`GET /memberships/{id}`**(상세)를 조회해 상품·금액·결제수단·가입일·자동갱신일을
/// 채운다. 상단 X 또는 하단 "확인"을 누르면 이 화면을 닫는다(호출부가 구독 플로우를
/// 걷어내고 마이펫 상세로 복귀시킨다).
class MembershipCompleteScreen extends ConsumerWidget {
  const MembershipCompleteScreen({super.key, required this.membershipId});

  final int membershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(membershipDetailProvider(membershipId));
    final MembershipDetail? detail = detailAsync.asData?.value;
    final name = detail?.membershipName.trim();
    final subtitleName = (name == null || name.isEmpty) ? '멤버십' : name;

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
                      _CompleteHeader(subtitleName: subtitleName),
                      const SizedBox(height: 24),
                      detailAsync.when(
                        data: (d) => _InfoCard(detail: d),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                        error: (_, _) => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            '상세 정보를 불러오지 못했어요.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
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
}

/// 보라 체크 원 + "구독이 완료되었습니다." + 안내 문구.
class _CompleteHeader extends StatelessWidget {
  const _CompleteHeader({required this.subtitleName});

  final String subtitleName;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          '구독이 완료되었습니다.',
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
        Text(
          '이제 $subtitleName 혜택을\n이용할 수 있어요.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: -0.66,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 구독 상세 정보 카드(6행).
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.detail});

  final MembershipDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row('구독 상품', detail.membershipName),
          const SizedBox(height: 16),
          _row('구독 금액', '${formatThousands(detail.paymentAmount)}원', emphasize: true),
          const SizedBox(height: 16),
          _row('구독 방식', detail.paymentCycleLabel),
          const SizedBox(height: 16),
          _row('결제 수단', detail.cardLabel),
          const SizedBox(height: 16),
          _row('구독 시작일', detail.joinDtDisplay),
          const SizedBox(height: 16),
          _row('자동 갱신일', detail.nextBillingDtDisplay),
        ],
      ),
    );
  }

  /// 라벨(좌, Medium/secondary) + 값(우, SemiBold/muted, 강조 시 Bold/strong).
  Widget _row(String label, String value, {bool emphasize = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
