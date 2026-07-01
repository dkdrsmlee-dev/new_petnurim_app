import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/page_header.dart';
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
  static const Color _textStrongColor = Color(0xFF30343C);
  static const Color _textMutedColor = Color(0xFF51565F);
  static const Color _placeholderColor = Color(0xFFA2ADBE);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _sectionDividerColor = Color(0xFFF4F6F8);
  static const Color _badgeBackgroundColor = Color(0xFFF4EFFE);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petDetailAsync = ref.watch(myPetDetailProvider(myPetId));

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
                ? ref.read(apiClientProvider).uri('/api/v1/files/${pet.profileFileId}').toString()
                : null;
            final isPrimary = pet.representYn == 'Y';
            final ageText = '${pet.petAge}살';
            final genderText = pet.genderCodeNm ?? (pet.genderCode == 'MALE' ? '남아' : '여아');
            final breedText = pet.breedNameKor ?? '믹스';

            // Calculate mock next payment date (1 month from today)
            final now = DateTime.now();
            final nextPaymentDate = DateTime(now.year, now.month + 1, now.day);
            final nextPaymentStr = '${nextPaymentDate.year}-${nextPaymentDate.month.toString().padLeft(2, '0')}-${nextPaymentDate.day.toString().padLeft(2, '0')}';

            return ListView(
              children: [
                // 1. Pet Profile Card Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Pet Photo
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF1F3F5),
                          border: Border.all(color: _borderColor, width: 1),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl == null
                            ? const Icon(
                                Icons.pets,
                                color: _placeholderColor,
                                size: 36,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Pet Specs
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.petName,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textStrongColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$ageText · $breedText · $genderText',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                color: _textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit button
                      OutlinedButton(
                        onPressed: () {
                          // 상세 정보 수정 흐름 진입 (3단계-2에서 구현 예정)
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _borderColor, width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '수정',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textMutedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Section Divider
                Container(
                  height: 6,
                  color: _sectionDividerColor,
                ),

                // 2. Membership Info Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '멤버십 정보',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textStrongColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isPrimary) ...[
                        // Subscribed Membership View
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Column(
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
                                  const SizedBox(width: 8),
                                  const Text(
                                    '브론즈',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _textStrongColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFFE8EBF1), height: 1),
                              const SizedBox(height: 16),
                              _buildRowWithArrow('결제 내역', () {}),
                              const SizedBox(height: 16),
                              _buildKeyValueRow('다음 결제일', nextPaymentStr),
                              const SizedBox(height: 16),
                              _buildKeyValueRow('월 구독료', '10,000원'),
                            ],
                          ),
                        ),
                      ] else ...[
                        // No Membership View
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.stars_outlined,
                                color: _placeholderColor,
                                size: 36,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '이용 중인 멤버십이 없어요.',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _textStrongColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '멤버십을 구독하고 혜택을 받아보세요.',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  color: _textMutedColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // 멤버십 구독하기 페이지 연동
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '멤버십 구독하기',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '리워드 정보',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textStrongColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildRowWithArrow('리워드 내역', () {}),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFE8EBF1), height: 1),
                            const SizedBox(height: 16),
                            _buildKeyValueRow('이번 달 적립', '28,000P'),
                            const SizedBox(height: 16),
                            _buildKeyValueRow('이번 달 사용', '10,000원'),
                          ],
                        ),
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

  Widget _buildRowWithArrow(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _textStrongColor,
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: _placeholderColor,
            size: 20,
          ),
        ],
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
            fontSize: 14,
            color: _textMutedColor,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _textStrongColor,
          ),
        ),
      ],
    );
  }
}
