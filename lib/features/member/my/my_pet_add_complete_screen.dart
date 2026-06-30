import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';

class MyPetAddCompleteScreen extends ConsumerWidget {
  final String petType;
  final String name;
  final String? breed;
  final String? profileImagePath;
  final int age;
  final String? dateBecameFamily;
  final String gender;
  final bool neutered;
  final String weight;
  final String? weightDate;
  final bool isPrimary;

  const MyPetAddCompleteScreen({
    super.key,
    required this.petType,
    required this.name,
    this.breed,
    this.profileImagePath,
    required this.age,
    this.dateBecameFamily,
    required this.gender,
    required this.neutered,
    required this.weight,
    this.weightDate,
    required this.isPrimary,
  });

  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _textStrongColor = Color(0xFF30343C);
  static const Color _textMutedColor = Color(0xFF51565F);
  static const Color _textValueColor = Color(0xFF87909E);
  static const Color _dividerColor = Color(0xFFE8EBF1);

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
    final hasImage = profileImagePath != null && profileImagePath!.isNotEmpty;

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
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.54,
                        color: _textStrongColor,
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
                      color: _textStrongColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
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
                          fontFamily: 'Pretendard',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.66,
                          color: _textStrongColor,
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
                          color: const Color(0xFFF4F6F8),
                          border: Border.all(color: const Color(0xFFF0F2F5), width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: hasImage
                            ? Image.file(
                                File(profileImagePath!),
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: SvgPicture.asset(
                                  'assets/images/ic_pet_foot_default.svg',
                                  width: 60,
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 3. 마이펫 등록 정보 요약 카드 (Round 16px)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _buildInfoRow('이름', name),
                          _buildInfoRow('품종', breed ?? '믹스'),
                          _buildInfoRow('나이', '$age살'),
                          _buildInfoRow('가족이 된 날', _formatDate(dateBecameFamily)),
                          _buildInfoRow('성별', gender == 'MALE' ? '남아' : '여아'),
                          _buildInfoRow('중성화', neutered ? '했어요' : '안했어요'),
                          _buildInfoRow('체중', '${weight}Kg'),
                          _buildInfoRow('체중 측정일', _formatDate(weightDate), isLast: true),
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
                  context.go(AppRoutes.myPetList);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
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
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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

  Widget _buildInfoRow(String title, String value, {bool isLast = false}) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: _dividerColor, width: 1),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textMutedColor,
              letterSpacing: -0.66,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textValueColor,
                letterSpacing: -0.66,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
