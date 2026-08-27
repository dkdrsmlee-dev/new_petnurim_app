import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/authed_file_image.dart';

import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/nurim_refreshable.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';
import '../domain/pet_codes.dart';
import '../domain/pet_models.dart';
import '../domain/membership_models.dart';
import '../data/pet_repository.dart';
import '../data/membership_repository.dart';
import 'membership_benefits_screen.dart';
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
      ToastUtil.show(context, '대표 펫 설정에 실패했습니다: $e');
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(myPetsListProvider);
    ref.invalidate(petMembershipProvider); // 펫별 멤버십 칩 갱신
    await ref.read(myPetsListProvider.future);
  }

  /// "멤버십 가입하기" 칩(미가입) → 해당 펫 멤버십 혜택 화면(구독 진입점).
  void _openBenefits(String myPetId) {
    final petId = int.tryParse(myPetId);
    if (petId == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            settings:
                const RouteSettings(name: MembershipBenefitsScreen.routeName),
            builder: (_) => MembershipBenefitsScreen(myPetId: petId),
          ),
        )
        .then((_) {
      ref.invalidate(myPetsListProvider);
      ref.invalidate(petMembershipProvider);
    });
  }

  Widget _buildContent(List<MyPetListItem> serverPets) {
    _serverPets = serverPets;
    _customPetList = serverPets.map((item) {
        final rewardSummary =
            ref.watch(petRewardSummaryProvider(item.myPetId)).asData?.value;
        return NurimPetCardData(
          name: item.petName,
          breed: item.breedNameKor ?? '믹스',
          ageText: '${item.petAge}살',
          genderText: PetGender.label(item.genderCode, serverName: item.genderCodeNm),
          membershipTier: ref.watch(petMembershipProvider(item.myPetId)).maybeWhen(
            data: (status) => status.petCardChipLabel,
            orElse: () => '-',
          ),
          rewardText: rewardSummary != null
              ? '${formatThousands(rewardSummary.currentReward)}P'
              : '-',
          isPrimary: YesNo.isYes(item.representYn),
          imageProvider: item.profileFileId != null
              ? AuthedFileImageX.of(ref, item.profileFileId!, variant: 'thumb')
              : null,
          onMembershipJoinTap: () => _openBenefits(item.myPetId),
        );
      }).toList();

    final list = _customPetList!;

    return Column(
      children: [
        Padding(
          // Figma: content 좌우 16 + Title 자체 px 4 = 20, 헤더 아래 16
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '전체',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.66,
                      color: AppColors.textSecondary, // Figma #87909E
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${list.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.66,
                      color: AppColors.textStrong, // Figma #30343C
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.66,
                    color: AppColors.textSecondary, // Figma #87909E
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: NurimRefreshable(
            onRefresh: _refresh,
            child: list.isEmpty
              ? const RefreshableCenter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pets,
                        color: AppColors.placeholder,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        '등록된 마이펫이 없습니다.\n마이 펫을 등록해 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                              ref.invalidate(petMembershipProvider);
                            });
                          }
                        }
                      },
                    );
                  },
                ),
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
                    disabledBackgroundColor: AppColors.borderLight, // Figma #E8EBF1
                    disabledForegroundColor: AppColors.placeholder, // Figma #A2ADBE
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
