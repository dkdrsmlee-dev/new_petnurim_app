import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// 프로필 사진 소스 선택(사진 촬영 / 앨범 선택) 공통 바텀시트.
///
/// 마이펫 등록/수정 화면에 중복 구현돼 있던 사진 선택 시트를 공통화한 것.
/// 항목을 탭하면 시트를 닫은 뒤 [onCamera]/[onGallery] 콜백을 호출한다.
Future<void> showPhotoSourceSheet(
  BuildContext context, {
  required VoidCallback onCamera,
  required VoidCallback onGallery,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 핸들 인디케이터
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 52,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              _PhotoSourceTile(
                iconAsset: 'assets/images/ic_camera.svg',
                label: '사진 촬영',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onCamera();
                },
              ),
              const SizedBox(height: 8),
              _PhotoSourceTile(
                iconAsset: 'assets/images/ic_album.svg',
                label: '앨범 선택',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onGallery();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        iconAsset,
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
          AppColors.textMuted,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: -0.66,
        ),
      ),
      onTap: onTap,
    );
  }
}
