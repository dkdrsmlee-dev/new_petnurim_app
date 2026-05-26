import 'package:flutter/material.dart';

/// Figma `Page_header` 컴포넌트 스펙 기반의 헤더 위젯.
///
/// 좌측에 이전 페이지로 돌아가는 화살표 버튼 (`<-`), 중앙에 타이틀을 배치하며,
/// 하단에는 1px 두께의 경계선(색상: `#E8EBF1`)을 제공합니다.
class NurimPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const NurimPageHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.showBackButton = true,
  });

  /// 헤더 중앙에 표시될 타이틀 텍스트
  final String title;

  /// 뒤로가기 버튼 클릭 시 수행될 콜백 (지정하지 않을 경우 기본 Navigator.maybePop 수행)
  final VoidCallback? onBackPressed;

  /// 뒤로가기 버튼 노출 여부 (기본값: true)
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EBF1), // Figma border-b Gray 30: #E8EBF1
            width: 1.0,
          ),
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w600, // SemiBold
            height: 1.4,
            letterSpacing: -0.66,
            color: Color(0xFF30343C), // strong text color
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                tooltip: '뒤로',
                onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Color(0xFF30343C),
                ),
              )
            : null,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
