import 'package:flutter/material.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/pet_select_card.dart';
import 'camera_screen.dart';
import 'shooting_history_screen.dart';
import '../../core/theme/app_colors.dart';

/// 등록된 펫이 2마리 이상일 때 표시되는 펫 선택 화면 (Figma USR-EVT-018 - 마이펫 있을 때)
///
/// 카드를 탭하면 선택한 펫 정보를 가지고 [CameraScreen]으로 이동합니다.
class PetSelectScreen extends StatelessWidget {
  const PetSelectScreen({super.key, required this.pets});

  final List<PetSelectCardData> pets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const NurimPageHeader(
        title: '마이 펫 촬영',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 텍스트
              const Text(
                '촬영 미션에 참여할\n아이를 선택해 주세요.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 32),

              // 펫 카드 목록
              Expanded(
                child: ListView.separated(
                  itemCount: pets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    return PetSelectCard(
                      data: pet,
                      onTap: () {
                        // 선택한 펫으로 카메라 화면 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CameraScreen(),
                          ),
                        );
                      },
                      onHistoryTap: () {
                        // 촬영 내역 화면으로 펫 데이터를 동반하여 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShootingHistoryScreen(petData: pet),
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
