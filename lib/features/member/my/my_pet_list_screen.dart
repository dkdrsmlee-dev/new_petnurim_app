import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';

class MyPetListScreen extends ConsumerStatefulWidget {
  const MyPetListScreen({super.key});

  @override
  ConsumerState<MyPetListScreen> createState() => _MyPetListScreenState();
}

class _MyPetListScreenState extends ConsumerState<MyPetListScreen> {
  bool _isEditMode = false;
  int? _selectedPetIndex;
  late List<NurimPetCardData> _petList;

  // 피그마 디자인(USR-MYP-011)과 일치하는 펫 리스트 더미데이터
  static const List<NurimPetCardData> _staticPets = [
    NurimPetCardData(
      name: '콩두리',
      breed: '시바',
      ageText: '2살',
      genderText: '남아',
      membershipTier: '브론즈',
      rewardText: '28,000P',
      isPrimary: true,
      imageProvider: NetworkImage(
        'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=150&h=150&fit=crop',
      ),
    ),
    NurimPetCardData(
      name: '모찌',
      breed: '시바',
      ageText: '2살',
      genderText: '남아',
      membershipTier: '멤버십 가입하기',
      rewardText: '28,000P',
      isPrimary: false,
      imageProvider: NetworkImage(
        'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=150&h=150&fit=crop',
      ),
    ),
    NurimPetCardData(
      name: '치즈',
      breed: '시바',
      ageText: '2살',
      genderText: '남아',
      membershipTier: '멤버십 가입하기',
      rewardText: '28,000P',
      isPrimary: false,
      imageProvider: NetworkImage(
        'https://images.unsplash.com/photo-1596492784531-6e6eb5ea9993?w=150&h=150&fit=crop',
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _petList = List.from(_staticPets);
  }

  void _updatePrimaryPet() {
    if (_selectedPetIndex == null) return;
    final selectedPet = _petList[_selectedPetIndex!];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '${selectedPet.name}가 대표 펫으로\n설정되었어요.',
        confirmText: '확인',
        onConfirm: () {
          setState(() {
            for (int i = 0; i < _petList.length; i++) {
              final pet = _petList[i];
              _petList[i] = NurimPetCardData(
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const NurimPageHeader(
        title: '마이 펫',
        showDivider: false,
      ),
      body: SafeArea(
        child: Column(
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
                        '${_petList.length}',
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
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _petList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final pet = _petList[index];
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
                      onPressed: () {
                        // 마이 펫 추가 페이지 연결 예정
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
        ),
      ),
    );
  }
}
