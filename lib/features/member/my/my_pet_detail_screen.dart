import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_bootstrap.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';
import '../../../core/widgets/pet_info_detail.dart';
import '../domain/pet_models.dart';
import '../data/pet_repository.dart';

final myPetDetailProvider = FutureProvider.autoDispose.family<MyPetDetailResponse, String>((ref, myPetId) async {
  return await ref.read(petRepositoryProvider).getMyPetDetail(myPetId);
});

class MyPetDetailScreen extends ConsumerWidget {
  const MyPetDetailScreen({
    super.key,
    required this.myPetId,
  });

  final String myPetId;

  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _primaryStrongColor = Color(0xFF7025FF);
  static const Color _textStrongColor = Color(0xFF30343C);
  static const Color _textMutedColor = Color(0xFF51565F);
  static const Color _textSecondaryColor = Color(0xFF87909E);
  static const Color _placeholderColor = Color(0xFFA2ADBE);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _badgeTextColor = Color(0xFF6C737F);
  static const Color _badgeBackgroundColor = Color(0xFFF4F6F8);
  static const Color _sectionDividerColor = Color(0xFFF4F6F8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petDetailAsync = ref.watch(myPetDetailProvider(myPetId));
    final token = ref.watch(accessTokenProvider);

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
            child: CircularProgressIndicator(color: _primaryColor),
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
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: _textMutedColor,
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
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
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
            final imageUrl = pet.profileFileId != null
                ? ref.read(apiClientProvider).uri('/api/v1/files/${pet.profileFileId}/download').toString()
                : null;
            final isPrimary = pet.representYn == 'Y';
            final ageText = '${pet.petAge}살';
            final genderText = pet.genderCodeNm ?? (pet.genderCode == 'MALE' ? '남아' : '여아');
            final breedText = pet.breedNameKor ?? '믹스';

            // Calculate mock next payment date (1 month from today)
            final now = DateTime.now();
            final nextPaymentDate = DateTime(now.year, now.month + 1, now.day);
            final nextPaymentStr = '${nextPaymentDate.year}.${nextPaymentDate.month.toString().padLeft(2, '0')}.${nextPaymentDate.day.toString().padLeft(2, '0')}';

            return ListView(
              children: [
                // 1. Pet Profile Card Section (Figma node: 234:21712)
                NurimPetInfoDetail(
                  pet: NurimPetCardData(
                    name: pet.petName,
                    breed: breedText,
                    ageText: ageText,
                    genderText: genderText,
                    imageProvider: (imageUrl != null && token != null)
                        ? NetworkImage(
                            imageUrl,
                            headers: {
                              'Authorization': 'Bearer $token',
                              'access-token': token,
                            },
                          )
                        : null,
                    isPrimary: isPrimary,
                    membershipTier: '-',
                    rewardText: '28,000PR',
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
                  color: _sectionDividerColor,
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
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isPrimary) ...[
                        // Subscribed Membership View (Figma node: 231:19551)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Bronze icon or circle
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFF4C21B), // Bronze color
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '브론즈',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: _textStrongColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _badgeBackgroundColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '현재 이용 중',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _badgeTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {
                                    // 결제 내역 화면 연동
                                  },
                                  child: const Row(
                                    children: [
                                      Text(
                                        '결제 내역',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: _textSecondaryColor,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right,
                                        color: _textSecondaryColor,
                                        size: 16,
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
                                border: Border.all(color: _borderColor),
                              ),
                              child: Column(
                                children: [
                                  _buildKeyValueRow('다음 결제일', nextPaymentStr),
                                  const SizedBox(height: 16),
                                  _buildKeyValueRow('월 구독료', '10,000원'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      // 멤버십 관리 페이지 연동
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF7F6FF), // violet/10
                                      foregroundColor: _primaryColor,
                                      minimumSize: const Size.fromHeight(48),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      '멤버십 관리',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
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
                            const SizedBox(height: 24),
                            const Text(
                              '이용 중인 멤버십이 없어요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _placeholderColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '멤버십을 구독하고 혜택을 받아보세요.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _placeholderColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton(
                              onPressed: () {
                                // 멤버십 혜택 보기 페이지 연동
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: _primaryColor, width: 1.0),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '멤버십 혜택 보기',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryStrongColor,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color: _primaryStrongColor,
                                    size: 16,
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
                  color: _sectionDividerColor,
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
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textSecondaryColor,
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
                                  const Text(
                                    '28,000PR',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: _textStrongColor,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  // 리워드 내역 화면 연동
                                },
                                child: const Row(
                                  children: [
                                    Text(
                                      '리워드 내역',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: _textSecondaryColor,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right,
                                      color: _textSecondaryColor,
                                      size: 16,
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
                              border: Border.all(color: _borderColor),
                            ),
                            child: Column(
                              children: [
                                _buildKeyValueRow('이번 달 적립', '6,000PR'),
                                const SizedBox(height: 16),
                                _buildKeyValueRow('이번 달 사용', '10,000원'),
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
        Text(
          key,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textMutedColor,
          ),
        ),
      ],
    );
  }
}
