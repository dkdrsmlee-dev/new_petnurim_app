import 'package:flutter/material.dart';
import '../../core/widgets/popup_header.dart';
import '../../core/theme/app_colors.dart';

/// 등록된 펫이 0마리일 때 표시되는 화면 (Figma USR-EVT-018 - 마이펫 없을 때)
///
/// "마이 펫 추가" 버튼을 탭하면 [onAddPetPressed]가 호출됩니다.
class PetEmptyScreen extends StatelessWidget {
  const PetEmptyScreen({super.key, this.onAddPetPressed});

  final VoidCallback? onAddPetPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PopupHeader(
        title: '마이 펫 촬영',
        showBackButton: true,
        showCloseButton: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 안내 텍스트
              const Text(
                '등록된 펫 정보가 없어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.placeholder,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '펫 정보 등록 후 진행해 주세요 :)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.placeholder,
                ),
              ),
              const SizedBox(height: 24),

              // 마이 펫 추가 버튼
              SizedBox(
                width: 283,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onAddPetPressed,
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                  label: const Text(
                    '마이 펫 추가',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.66,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7E4FFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
