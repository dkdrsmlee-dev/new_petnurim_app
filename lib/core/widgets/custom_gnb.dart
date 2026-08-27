import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

enum GnbMenu {
  // assetName은 Figma 아이콘 컴포넌트명(Icon/Home·Gift·Mycam·Rank·Event/24) 기준.
  home('홈', 'home'),
  gift('기프트', 'gift'),
  check('문진', 'mycam'),
  meta('경품메타', 'rank'),
  event('이벤트', 'event');

  final String label;
  final String assetName;

  const GnbMenu(this.label, this.assetName);

  /// Figma에서 내려받은 on/off 아이콘 경로 (활성 #7F4FFF · 비활성 #6C737F 색상 내장)
  String iconAsset(bool isActive) =>
      'assets/images/gnb/ic_gnb_${assetName}_${isActive ? 'on' : 'off'}.svg';
}

class CustomGnb extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomGnb({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 56 + bottomPadding, // Figma GNB Height: 56px + OS bottom padding
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight, // Figma border-t Gray 30: #E8EBF1
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // justify-between
          children: GnbMenu.values.asMap().entries.map((entry) {
            final int index = entry.key;
            final GnbMenu menu = entry.value;
            final bool isActive = currentIndex == index;

            return Expanded(
              child: _GnbOnOffItem(
                menu: menu,
                isActive: isActive,
                onTap: () => onTap(index),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GnbOnOffItem extends StatelessWidget {
  final GnbMenu menu;
  final bool isActive;
  final VoidCallback onTap;

  const _GnbOnOffItem({
    required this.menu,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Figma: 활성 violet/100 #7025FF · 비활성 gray/90 #6C737F
    final textColor = isActive ? AppColors.primaryStrong : AppColors.textTertiary;
    final fontWeight = isActive ? FontWeight.w600 : FontWeight.w500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. 아이콘 영역 (24px x 24px) — Figma SVG 원본(색상 내장)
          SvgPicture.asset(
            menu.iconAsset(isActive),
            width: 24,
            height: 24,
          ),
          const SizedBox(height: 2), // Figma Gap: 2px
          // 2. 텍스트 라벨 (Body/3xs: Pretendard 12px, line-height 1.4)
          Text(
            menu.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: fontWeight,
              color: textColor,
              letterSpacing: -0.66,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
