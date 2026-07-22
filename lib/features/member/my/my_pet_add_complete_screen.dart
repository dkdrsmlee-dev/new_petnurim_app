import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/authed_file_image.dart';
import '../data/member_repository.dart';
import '../data/pet_repository.dart';
import '../domain/pet_models.dart';
import 'my_pet_list_screen.dart';
import '../../../core/theme/app_colors.dart';

final myPetDetailProvider = FutureProvider.family.autoDispose<MyPetDetailResponse, String>((ref, myPetId) {
  return ref.read(petRepositoryProvider).getMyPetDetail(myPetId);
});

class MyPetAddCompleteScreen extends ConsumerWidget {
  final String myPetId;

  const MyPetAddCompleteScreen({
    super.key,
    required this.myPetId,
  });


  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final parts = rawDate.split('-');
      if (parts.length == 3) {
        return '${parts[0]}. ${parts[1].padLeft(2, '0')}. ${parts[2].padLeft(2, '0')}';
      }
    } catch (_) {}
    return rawDate;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(myPetDetailProvider(myPetId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(106),
        child: Column(
          children: [
            Container(height: 50, color: Colors.white),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(width: 24), // 좌측 화살표 없는 대칭 여백 확보
                  Expanded(
                    child: Text(
                      '등록 완료',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.54,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.go(AppRoutes.myPetList);
                    },
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: AppColors.textStrong,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: detailAsync.when(
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
                  '등록 정보를 불러오지 못했습니다.',
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
          data: (detail) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. 상단 서브 타이틀
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            '등록이 완료되었어요!\n이제 맞춤 케어를 시작해볼까요?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.66,
                              color: AppColors.textStrong,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 2. 프로필 이미지 중앙 배치 (100px)
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bgGray,
                              border: Border.all(color: const Color(0xFFF0F2F5), width: 1),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: detail.profileFileId != null
                                ? Image(
                                    image: AuthedFileImageX.of(ref, detail.profileFileId!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Stack(
                                      children: [
                                        Positioned(
                                          left: 20,
                                          top: 22.37,
                                          width: 60,
                                          child: SvgPicture.asset(
                                            'assets/images/ic_pet_foot_default.svg',
                                            fit: BoxFit.fitWidth,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      Positioned(
                                        left: 20,
                                        top: 22.37,
                                        width: 60,
                                        child: SvgPicture.asset(
                                          'assets/images/ic_pet_foot_default.svg',
                                          fit: BoxFit.fitWidth,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // 3. 마이펫 등록 정보 요약 카드 (Round 16px)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              _buildInfoRow('이름', detail.petName),
                              _buildInfoRow('품종', detail.breedNameKor ?? '믹스'),
                              _buildInfoRow('나이', '${detail.petAge}살'),
                              _buildInfoRow('가족이 된 날', _formatDate(detail.familyDt)),
                              _buildInfoRow('성별', detail.genderCodeNm ?? (detail.genderCode == 'MALE' ? '남아' : '여아')),
                              _buildInfoRow('중성화', detail.neuteredYn == 'Y' ? '했어요' : '안했어요'),
                              _buildInfoRow('체중', '${detail.weightKg}Kg'),
                              _buildInfoRow('체중 측정일', _formatDate(detail.weightMeasureDt), isLast: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // 4. 하단 확인 버튼
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      ref.invalidate(myPetsListProvider);
                      ref.invalidate(memberMyPageProvider);
                      context.go('${AppRoutes.home}?tab=5');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.66,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {bool isLast = false}) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.borderLight, width: 1),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: -0.66,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: -0.66,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
