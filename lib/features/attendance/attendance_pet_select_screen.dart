import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/pet_select_card.dart';
import 'attendance_screen.dart';

/// 출석 체크할 펫을 선택하는 화면 (등록 펫 2마리 이상일 때).
/// 카드를 탭하면 선택한 펫으로 [AttendanceScreen]으로 이동한다.
class AttendancePetSelectScreen extends StatelessWidget {
  const AttendancePetSelectScreen({
    super.key,
    required this.pets,
    required this.eventMasterId,
  });

  final List<PetSelectCardData> pets;
  final String eventMasterId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const NurimPageHeader(title: '마이 펫 출석'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '출석 체크할\n아이를 선택해 주세요.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: pets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    return PetSelectCard(
                      data: pet,
                      showHistory: false, // 펫별 출석 내역 API 없음 → 내역 버튼 숨김
                      onTap: () {
                        final petId = pet.petId;
                        if (petId == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceScreen(
                              eventMasterId: eventMasterId,
                              myPetId: petId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
