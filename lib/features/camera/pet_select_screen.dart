import 'package:flutter/material.dart';
import '../../core/widgets/popup_header.dart';
import '../../core/widgets/pet_select_card.dart';
import 'camera_screen.dart';

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
      appBar: PopupHeader(
        title: '마이 펫 촬영',
        showBackButton: true,
        showCloseButton: false,
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
                  fontFamily: 'Pretendard',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: Color(0xFF30343C),
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
                        // TODO: 해당 펫의 촬영 내역 화면으로 이동 (추후 구현)
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
