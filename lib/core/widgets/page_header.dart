import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

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
    this.actions,
    // Figma 공용 헤더(Page_header 89:5687)에는 하단 구분선이 없다.
    // 선이 필요한 화면만 showDivider: true 를 명시한다.
    this.showDivider = false,
  });

  /// 헤더 중앙에 표시될 타이틀 텍스트
  final String title;

  /// 뒤로가기 버튼 클릭 시 수행될 콜백 (지정하지 않을 경우 기본 Navigator.maybePop 수행)
  final VoidCallback? onBackPressed;

  /// 뒤로가기 버튼 노출 여부 (기본값: true)
  final bool showBackButton;

  /// 우측에 표시될 액션 버튼 목록
  final List<Widget>? actions;

  /// 하단 구분선 노출 여부 (기본값: true)
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: showDivider
            ? const Border(
                bottom: BorderSide(
                  color: AppColors.border, // Figma line/default: #D6DBE4
                  width: 1.0,
                ),
              )
            : null,
      ),
      child: AppBar(
        toolbarHeight: 56, // Figma Page_header height: 56px (89:5687)
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700, // Bold (700)
            height: 1.4,
            letterSpacing: -0.54, // Figma tracking: -0.54px
            color: AppColors.textStrong, // strong text color
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
                // Figma Page_header의 Icon/ArrowLeft/24 (색 #51565F 내장)
                icon: SvgPicture.asset(
                  'assets/images/ic_arrow_left_24.svg',
                  width: 24,
                  height: 24,
                ),
              )
            : null,
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
