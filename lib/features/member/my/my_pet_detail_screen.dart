import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/widgets/authed_file_image.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';
import '../../../core/widgets/pet_info_detail.dart';
import '../domain/membership_models.dart';
import '../domain/pet_codes.dart';
import '../domain/pet_models.dart';
import '../data/membership_repository.dart';
import '../data/pet_repository.dart';
import 'membership_benefits_screen.dart';
import 'membership_payment_history_screen.dart';
import 'pet_reward_history_screen.dart';
import '../../../core/theme/app_colors.dart';

final myPetDetailProvider = FutureProvider.autoDispose.family<MyPetDetailResponse, String>((ref, myPetId) async {
  return await ref.read(petRepositoryProvider).getMyPetDetail(myPetId);
});


class MyPetDetailScreen extends ConsumerWidget {
  const MyPetDetailScreen({
    super.key,
    required this.myPetId,
  });

  final String myPetId;


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petDetailAsync = ref.watch(myPetDetailProvider(myPetId));
    // 리워드 요약(총 보유/이번 달 적립·사용) — 로딩/실패 시 '-' 표시
    final reward = ref.watch(petRewardSummaryProvider(myPetId)).asData?.value;
    final currentRewardText =
        reward != null ? '${formatThousands(reward.currentReward)}PR' : '-';
    // 멤버십 상태(실데이터): 미가입/가입중/구독취소예정
    final membershipAsync = ref.watch(petMembershipProvider(myPetId));
    final MembershipInfo? membership = membershipAsync.asData?.value.membership;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '마이 펫 상세 정보',
        showDivider: false,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.myPetList);
          }
        },
      ),
      body: SafeArea(
        child: petDetailAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFFA6262),
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  '마이펫 상세 정보를 불러오지 못했습니다.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(myPetDetailProvider(myPetId)),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text(
                    '다시 시도',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          data: (pet) {
            final isPrimary = YesNo.isYes(pet.representYn);
            final ageText = '${pet.petAge}살';
            final genderText = PetGender.label(pet.genderCode, serverName: pet.genderCodeNm);
            final breedText = pet.breedNameKor ?? '믹스';

            return ListView(
              children: [
                // 1. Pet Profile Card Section (Figma node: 234:21712)
                NurimPetInfoDetail(
                  pet: NurimPetCardData(
                    name: pet.petName,
                    breed: breedText,
                    ageText: ageText,
                    genderText: genderText,
                    imageProvider: pet.profileFileId != null
                        ? AuthedFileImageX.of(ref, pet.profileFileId!,
                            variant: 'medium', downloadFallback: true)
                        : null,
                    isPrimary: isPrimary,
                    membershipTier: membership?.membershipName ?? '-',
                    rewardText: currentRewardText,
                  ),
                  actionLabel: '관리',
                  onActionPressed: () {
                    context.pushNamed(
                      AppRouteNames.myPetEdit,
                      pathParameters: {'myPetId': myPetId},
                    );
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                ),

                // Section Divider
                Container(
                  height: 6,
                  color: AppColors.bgGray,
                ),
                
                // 2. Membership Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '멤버십 정보',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (membershipAsync.isLoading) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ] else if (membership != null) ...[
                        // Subscribed Membership View (Figma node: 231:19551)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Figma Icon/Crown/24 (보라 크라운, #7F4FFF)
                                    SvgPicture.asset(
                                      'assets/images/ic_crown_24.svg',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      membership.membershipName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textStrong,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: membership.isCancelScheduled
                                            ? const Color(0xFFFFECEC)
                                            : AppColors.bgGray,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        membership.isCancelScheduled
                                            ? '해지 신청'
                                            : '현재 이용 중',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: membership.isCancelScheduled
                                              ? const Color(0xFFFF5F5F)
                                              : AppColors.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {
                                    // 멤버십 결제 내역 화면(USR-MBS-012)으로 이동.
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            MembershipPaymentHistoryScreen(
                                          membershipId: membership.membershipId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      const Text(
                                        '결제 내역',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      // Figma Icon/ArrowRight/16 (#909AA9)
                                      SvgPicture.asset(
                                        'assets/images/ic_arrow_right_16.svg',
                                        width: 16,
                                        height: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  _buildKeyValueRow(
                                    membership.isCancelScheduled
                                        ? '이용 종료일'
                                        : '다음 결제일',
                                    membership.nextBillingDt.replaceAll('-', '.'),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildKeyValueRow('월 구독료',
                                      '${formatThousands(membership.monthlyFee)}원'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      // 구독 중 멤버십 혜택 보기(Figma 231:19551) → 혜택 화면.
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          settings: const RouteSettings(
                                            name: MembershipBenefitsScreen.routeName,
                                          ),
                                          builder: (_) => MembershipBenefitsScreen(
                                            myPetId: int.parse(myPetId),
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF7F6FF), // violet/10
                                      foregroundColor: AppColors.primary,
                                      minimumSize: const Size.fromHeight(48),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      '멤버십 혜택 보기',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // No Membership View (Figma node: 541:9055)
                        Column(
                          children: [
                            // 섹션 타이틀 아래 공통 16 + 8 = 24 (Figma 간격)
                            const SizedBox(height: 8),
                            const Text(
                              '이용 중인 멤버십이 없어요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.placeholder,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '멤버십을 구독하고 혜택을 받아보세요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.placeholder,
                              ),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(
                                      name: MembershipBenefitsScreen.routeName,
                                    ),
                                    builder: (_) => MembershipBenefitsScreen(
                                      myPetId: int.parse(myPetId),
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.primary, width: 1.0),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '멤버십 혜택 보기',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryStrong,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Figma Icon/ArrowRight/16 (버튼 텍스트색 #7025FF)
                                  SvgPicture.asset(
                                    'assets/images/ic_arrow_right_16.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.primaryStrong,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Section Divider
                Container(
                  height: 6,
                  color: AppColors.bgGray,
                ),

                // 3. Reward Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '리워드 정보',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Coin Icon
                                  SvgPicture.asset(
                                    'assets/images/ic_coin.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentRewardText,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PetRewardHistoryScreen(
                                        myPetId: myPetId,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    const Text(
                                      '리워드 내역',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    // Figma Icon/ArrowRight/16 (#909AA9)
                                    SvgPicture.asset(
                                      'assets/images/ic_arrow_right_16.svg',
                                      width: 16,
                                      height: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                _buildKeyValueRow(
                                  '이번 달 적립',
                                  reward != null
                                      ? '${formatThousands(reward.currentMonthEarnReward)}PR'
                                      : '-',
                                ),
                                const SizedBox(height: 16),
                                _buildKeyValueRow(
                                  '이번 달 사용',
                                  reward != null
                                      ? '${formatThousands(reward.currentMonthUseReward)}원'
                                      : '-',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildKeyValueRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Figma Date list(238:23334)
        Text(
          key,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: -0.66,
            height: 1.4,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: -0.66,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
