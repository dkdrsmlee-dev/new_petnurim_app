import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/widgets/page_header.dart';
import '../data/membership_repository.dart';
import '../domain/membership_models.dart';

/// 멤버십 결제 내역 화면 (USR-MBS-012, Figma 239:26305).
///
/// 마이펫 상세 구독중 뷰의 "결제 내역 >"에서 진입. `GET /memberships/{id}/payments`로
/// 최신순 결제 이력을 받아 상품명·결제일·결제수단(카드)·금액을 리스트로 보여준다.
class MembershipPaymentHistoryScreen extends ConsumerWidget {
  const MembershipPaymentHistoryScreen({super.key, required this.membershipId});

  final int membershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(membershipPaymentsProvider(membershipId));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const NurimPageHeader(title: '결제 내역'),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => const Center(
          child: Text(
            '결제 내역을 불러오지 못했습니다.',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ),
        data: _buildBody,
      ),
    );
  }

  Widget _buildBody(MembershipPaymentPage pageData) {
    return Column(
      children: [
        _listHeader(pageData.totalCount),
        Expanded(
          child: pageData.items.isEmpty
              ? const Center(
                  child: Text(
                    '결제 내역이 없어요.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.placeholder,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: pageData.items.length,
                  itemBuilder: (context, i) => _row(pageData.items[i]),
                ),
        ),
      ],
    );
  }

  /// "전체 N" + "최신 내역 순" 헤더(회색 바).
  Widget _listHeader(int total) {
    return Container(
      width: double.infinity,
      color: AppColors.bgGray,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                '전체 ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.66,
                ),
              ),
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textStrong,
                  letterSpacing: -0.66,
                ),
              ),
            ],
          ),
          const Text(
            '최신 내역 순',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: -0.66,
            ),
          ),
        ],
      ),
    );
  }

  /// 결제 내역 한 건(상품명·결제일·카드 / 금액).
  Widget _row(MembershipPayment p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.membershipName.isEmpty ? '멤버십' : p.membershipName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.paidDtDisplay,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.cardLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${formatThousands(p.paymentAmount)}원',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              letterSpacing: -0.66,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
