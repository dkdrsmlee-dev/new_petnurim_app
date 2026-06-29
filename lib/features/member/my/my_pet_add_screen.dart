import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_header.dart';

class MyPetAddScreen extends ConsumerStatefulWidget {
  const MyPetAddScreen({super.key});

  @override
  ConsumerState<MyPetAddScreen> createState() => _MyPetAddScreenState();
}

class _MyPetAddScreenState extends ConsumerState<MyPetAddScreen> {
  // 선택된 펫 종류 공통 코드: 'DOG' (강아지) 또는 'CAT' (고양이)
  String? _selectedPetType;

  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _labelMutedColor = Color(0xFF87909E);
  static const Color _bgGrayColor = Color(0xFFF8F9FB);
  static const Color _buttonDisabledBgColor = Color(0xFFE8EBF1);
  static const Color _buttonDisabledTextColor = Color(0xFFA2ADBE);

  Widget _buildPetTypeCard({
    required String typeCode,
    required String label,
    required String assetPath,
  }) {
    final isSelected = _selectedPetType == typeCode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPetType = typeCode;
          });
        },
        child: Container(
          height: 176,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _primaryColor : _borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bgGrayColor,
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      Positioned(
                        left: typeCode == 'DOG' ? 8.853 : 10.536,
                        top: typeCode == 'DOG' ? 13.301 : 14.101,
                        width: typeCode == 'DOG' ? (70 * 0.74705) : (70 * 0.69896),
                        height: typeCode == 'DOG' ? (70 * 1.04856) : (70 * 1.16853),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.pets,
                                size: 40,
                                color: isSelected ? _primaryColor : _labelMutedColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 종류 라벨 텍스트
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // SemiBold
                  letterSpacing: -0.66,
                  color: isSelected ? _primaryColor : _labelMutedColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const NurimPageHeader(
        title: '마이 펫 추가',
        showDivider: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 질문 영역
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 32),
              child: Text(
                '어떤 반려동물과\n함께하고 있나요?',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 20,
                  fontWeight: FontWeight.w700, // Bold
                  letterSpacing: -0.66,
                  color: Color(0xFF30343C), // strong text color
                  height: 1.4,
                ),
              ),
            ),
            // 종류 선택 카드 목록 영역 (Row)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildPetTypeCard(
                    typeCode: 'DOG',
                    label: '강아지',
                    assetPath: 'assets/images/banner/ic_dog_select.png',
                  ),
                  const SizedBox(width: 12),
                  _buildPetTypeCard(
                    typeCode: 'CAT',
                    label: '고양이',
                    assetPath: 'assets/images/banner/ic_cat_select.png',
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 하단 '다음' 버튼 영역
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _selectedPetType == null
                    ? null
                    : () {
                        // 다음 마이 펫 상세 정보 입력 단계로 라우팅 연동 예정
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _buttonDisabledBgColor,
                  disabledForegroundColor: _buttonDisabledTextColor,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w600, // SemiBold
                    letterSpacing: -0.66,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
