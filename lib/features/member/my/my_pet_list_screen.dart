import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';

class MyPetListScreen extends StatelessWidget {
  const MyPetListScreen({super.key});

  // 피그마 디자인(USR-MYP-011)과 일치하는 펫 리스트 더미데이터
  static const List<NurimPetCardData> _pets = [
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
      name: '초코비',
      breed: '시바',
      ageText: '2살',
      genderText: '남아',
      membershipTier: '브론즈',
      rewardText: '28,000P',
      isPrimary: false,
      imageProvider: NetworkImage(
        'https://images.unsplash.com/photo-1596492784531-6e6eb5ea9993?w=150&h=150&fit=crop',
      ),
    ),
  ];

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
            // Title 영역 (전체 X / 편집)
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
                        '${_pets.length}',
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
                      // 편집 기능 지원 예정
                    },
                    child: const Text(
                      '편집',
                      style: TextStyle(
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
                itemCount: _pets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  return NurimPetCard(
                    pet: pet,
                    onPressed: () {
                      // 펫 정보 수정 등 이동 예정
                    },
                  );
                },
              ),
            ),
            // 하단 마이 펫 추가 버튼 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
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
