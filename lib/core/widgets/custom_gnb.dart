import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum GnbMenu {
  home('홈', 'ic_home', Icons.home_outlined, Icons.home),
  gift('기프트', 'ic_gift', Icons.card_giftcard_outlined, Icons.card_giftcard),
  check('문진', 'ic_check', Icons.assignment_outlined, Icons.assignment),
  meta('경품메타', 'ic_meta', Icons.emoji_events_outlined, Icons.emoji_events),
  event('이벤트', 'ic_event', Icons.campaign_outlined, Icons.campaign);

  final String label;
  final String assetName;
  final IconData defaultIcon;
  final IconData activeIcon;

  const GnbMenu(this.label, this.assetName, this.defaultIcon, this.activeIcon);
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
    final textColor = isActive ? AppColors.primaryStrong : AppColors.textTertiary;
    final fontWeight = isActive ? FontWeight.w600 : FontWeight.w500;
    final stateStr = isActive ? 'active' : 'inactive';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. 아이콘 영역 (24px x 24px)
          SizedBox(
            width: 24,
            height: 24,
            child: Image.asset(
              'assets/icons/${menu.assetName}_$stateStr.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // 에셋이 준비되지 않았을 경우 디폴트 Material 아이콘을 그립니다.
                return Icon(
                  isActive ? menu.activeIcon : menu.defaultIcon,
                  size: 20,
                  color: textColor,
                );
              },
            ),
          ),
          const SizedBox(height: 2), // Figma Gap: 2px
          // 2. 텍스트 라벨 (12px, Pretendard)
          Text(
            menu.label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: fontWeight,
              color: textColor,
              letterSpacing: -0.66,
            ),
          ),
        ],
      ),
    );
  }
}
