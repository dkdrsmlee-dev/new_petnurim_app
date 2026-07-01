import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../app/app_routes.dart';

import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';
import '../domain/pet_models.dart';
import '../data/pet_repository.dart';

final myPetsListProvider = FutureProvider.autoDispose<List<MyPetListItem>>((ref) async {
  final response = await ref.read(petRepositoryProvider).getMyPetsList(limit: 100);
  return response.items;
});

class MyPetListScreen extends ConsumerStatefulWidget {
  const MyPetListScreen({super.key});

  @override
  ConsumerState<MyPetListScreen> createState() => _MyPetListScreenState();
}

class _MyPetListScreenState extends ConsumerState<MyPetListScreen> {
  bool _isEditMode = false;
  int? _selectedPetIndex;
  List<NurimPetCardData>? _customPetList;

  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _textMutedColor = Color(0xFF51565F);
  static const Color _placeholderColor = Color(0xFFA2ADBE);
  void _updatePrimaryPet() {
    if (_selectedPetIndex == null || _customPetList == null) return;
    final selectedPet = _customPetList![_selectedPetIndex!];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '${selectedPet.name}가 대표 펫으로\n설정되었어요.',
        confirmText: '확인',
        onConfirm: () {
          setState(() {
            for (int i = 0; i < _customPetList!.length; i++) {
              final pet = _customPetList![i];
              _customPetList![i] = NurimPetCardData(
                name: pet.name,
                breed: pet.breed,
                ageText: pet.ageText,
                genderText: pet.genderText,
                membershipTier: pet.membershipTier,
                rewardText: pet.rewardText,
                isPrimary: i == _selectedPetIndex,
                imageProvider: pet.imageProvider,
              );
            }
            // 대표 펫 설정 완료 확인 팝업 확인 터치 후, 편집 모드 자동 종료 및 인덱스 초기화
            _isEditMode = false;
            _selectedPetIndex = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(myPetsListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '마이 펫',
        showDivider: false,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
      body: SafeArea(
        child: petsAsync.when(
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
                  '마이펫 목록을 불러오지 못했습니다.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: _textMutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _customPetList = null;
                    });
                    ref.invalidate(myPetsListProvider);
                  },
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
          data: (serverPets) {
            _customPetList ??= serverPets.map((item) {
                final imageUrl = item.profileFileId != null
                    ? ref.read(apiClientProvider).uri('/api/v1/files/${item.profileFileId}').toString()
                    : null;

                return NurimPetCardData(
                  name: item.petName,
                  breed: item.breedNameKor ?? '믹스',
                  ageText: '${item.petAge}살',
                  genderText: item.genderCodeNm ?? (item.genderCode == 'MALE' ? '남아' : '여아'),
                  membershipTier: item.representYn == 'Y' ? '브론즈' : '멤버십 가입하기',
                  rewardText: '28,000P',
                  isPrimary: item.representYn == 'Y',
                  imageProvider: imageUrl != null ? NetworkImage(imageUrl) : null,
                );
              }).toList();

            final list = _customPetList!;

            return Column(
              children: [
                // Title 영역 (전체 X / 편집 <=> 완료)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '전체',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.66,
                              color: Color(0xFF87909E),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${list.length}',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.66,
                              color: Color(0xFF30343C),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isEditMode = !_isEditMode;
                            // 편집 모드 해제 또는 진입 시 선택된 인덱스 초기화
                            _selectedPetIndex = null;
                          });
                        },
                        child: Text(
                          _isEditMode ? '완료' : '편집',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.66,
                            color: Color(0xFF87909E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Pet list 영역 (세로 리스트)
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.pets,
                                color: _placeholderColor,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '등록된 마이펫이 없습니다.\n마이 펫을 등록해 주세요.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  color: _placeholderColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: list.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final pet = list[index];
                            return NurimPetCard(
                              pet: pet,
                              showSelectionControl: _isEditMode,
                              isSelected: _isEditMode && (_selectedPetIndex == index),
                              onSelectionChanged: () {
                                if (_isEditMode) {
                                  setState(() {
                                    _selectedPetIndex = index;
                                  });
                                }
                              },
                              onPressed: () {
                                if (_isEditMode) {
                                  setState(() {
                                    _selectedPetIndex = index;
                                  });
                                } else {
                                  // 일반 모드에서의 상세조회/수정 진입 (추후 구현 예정)
                                }
                              },
                            );
                          },
                        ),
                ),
                // 하단 버튼 영역 (마이 펫 추가 vs 대표 펫 설정)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isEditMode
                      ? ElevatedButton(
                          onPressed: _selectedPetIndex == null
                              ? null
                              : () {
                                  _updatePrimaryPet();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7F4FFF),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE8EBF1),
                            disabledForegroundColor: const Color(0xFF909AA9),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          child: const Text(
                            '대표 펫 설정',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.66,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            await context.push(AppRoutes.myPetAdd);
                            setState(() {
                              _customPetList = null;
                            });
                            ref.invalidate(myPetsListProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7F4FFF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '마이 펫 추가',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.66,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SvgPicture.asset(
                                'assets/images/ic_add.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
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
}
