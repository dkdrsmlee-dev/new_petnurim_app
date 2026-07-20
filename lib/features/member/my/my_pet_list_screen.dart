import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/authed_file_image.dart';

import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';
import '../domain/pet_models.dart';
import '../data/pet_repository.dart';
import '../../../core/theme/app_colors.dart';

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
  List<MyPetListItem>? _serverPets;


  Future<void> _updatePrimaryPet() async {
    if (_selectedPetIndex == null || _serverPets == null) return;
    final selectedPetItem = _serverPets![_selectedPetIndex!];

    try {
      final petDetail = await ref.read(petRepositoryProvider).getMyPetDetail(selectedPetItem.myPetId);

      await ref.read(petRepositoryProvider).updateMyPet(
        myPetId: selectedPetItem.myPetId,
        petTypeCode: petDetail.petTypeCode,
        petName: petDetail.petName,
        petAge: petDetail.petAge,
        genderCode: petDetail.genderCode,
        neuteredYn: petDetail.neuteredYn,
        weightKg: petDetail.weightKg,
        representYn: 'Y',
        petBreedId: int.tryParse(petDetail.petBreedId),
        profileFileId: petDetail.profileFileId != null ? int.tryParse(petDetail.profileFileId!) : null,
        familyDt: petDetail.familyDt,
        weightMeasureDt: petDetail.weightMeasureDt,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => EdgeButtonDialog(
          title: '${selectedPetItem.petName}가 대표 펫으로\n설정되었어요.',
          confirmText: '확인',
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            setState(() {
              _customPetList = null;
              _isEditMode = false;
              _selectedPetIndex = null;
            });
            ref.invalidate(myPetsListProvider);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대표 펫 설정에 실패했습니다: $e')),
      );
    }
  }

  Widget _buildContent(List<MyPetListItem> serverPets) {
    _serverPets = serverPets;
    _customPetList = serverPets.map((item) {
        return NurimPetCardData(
          name: item.petName,
          breed: item.breedNameKor ?? '믹스',
          ageText: '${item.petAge}살',
          genderText: item.genderCodeNm ?? (item.genderCode == 'MALE' ? '남아' : '여아'),
          membershipTier: item.representYn == 'Y' ? '브론즈' : '멤버십 가입하기',
          rewardText: '28,000P',
          isPrimary: item.representYn == 'Y',
          imageProvider: item.profileFileId != null
              ? AuthedFileImageX.of(ref, item.profileFileId!)
              : null,
        );
      }).toList();

    final list = _customPetList!;

    return Column(
      children: [
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
                      color: AppColors.textMuted,
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
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
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
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.pets,
                        color: AppColors.placeholder,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '등록된 마이펫이 없습니다.\n마이 펫을 등록해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          color: AppColors.placeholder,
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
                          if (_serverPets != null && index < _serverPets!.length) {
                            final petItem = _serverPets![index];
                            debugPrint('MyPetListScreen -> Tapped pet index: $index, myPetId: ${petItem.myPetId}');
                            context.pushNamed(
                              AppRouteNames.myPetDetail,
                              pathParameters: {'myPetId': petItem.myPetId},
                            ).then((_) {
                              ref.invalidate(myPetsListProvider);
                            });
                          }
                        }
                      },
                    );
                  },
                ),
        ),
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.borderLight,
                    disabledForegroundColor: AppColors.textDisabled,
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
                    backgroundColor: AppColors.primary,
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
  }

  Widget _buildErrorView() {
    return Center(
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
              color: AppColors.textMuted,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(myPetsListProvider);

    Widget bodyWidget;
    if (petsAsync.hasValue) {
      bodyWidget = _buildContent(petsAsync.value!);
    } else {
      bodyWidget = petsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => _buildErrorView(),
        data: (_) => const SizedBox.shrink(),
      );
    }

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
        child: bodyWidget,
      ),
    );
  }
}
