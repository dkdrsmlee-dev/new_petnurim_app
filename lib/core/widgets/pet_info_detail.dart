import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'pet_card.dart';

class NurimPetInfoDetail extends StatelessWidget {
  const NurimPetInfoDetail({
    super.key,
    required this.pet,
    this.actionLabel = '관리',
    this.onActionPressed,
    this.showActionButton = true,
    this.padding = EdgeInsets.zero,
  });

  final NurimPetCardData pet;
  final String actionLabel;
  final VoidCallback? onActionPressed;
  final bool showActionButton;
  final EdgeInsetsGeometry padding;

  static const TextStyle _descStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
    letterSpacing: -0.66,
    color: AppColors.textDisabled,
  );

  /// 종 · 나이 · 성별. NurimPetCard·PetSelectCard 와 순서·동작을 맞춘다.
  /// 품종만 남은 폭을 받아 말줄임하고 나이·성별은 줄어들지 않는다.
  /// (예전엔 나이·종·성별 순이었고 셋 다 맨 Text 라 긴 품종에서 28 넘쳤다)
  Widget _buildDescription() {
    final items = [pet.breed, pet.ageText, pet.genderText]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      final text = Text(items[i],
          maxLines: 1, overflow: TextOverflow.ellipsis, style: _descStyle);
      children.add(i == 0 ? Flexible(child: text) : text);
      if (i < items.length - 1) {
        children.add(const SizedBox(width: 4));
        children.add(const _DotSeparator());
        children.add(const SizedBox(width: 4));
      }
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pet Photo (Avatar, diameter 48px)
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0F2F5),
              // Figma: 보더 없음
            ),
            child: pet.imageProvider != null
                ? Image(
                    image: pet.imageProvider!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Stack(
                        children: [
                          Positioned(
                            left: 9.6,
                            top: 10.74,
                            width: 28.8,
                            child: SvgPicture.asset(
                              'assets/images/ic_pet_foot_default.svg',
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ],
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Stack(
                      children: [
                        Positioned(
                          left: 9.6,
                          top: 10.74,
                          width: 28.8,
                          child: SvgPicture.asset(
                            'assets/images/ic_pet_foot_default.svg',
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Positioned(
                        left: 9.6,
                        top: 10.74,
                        width: 28.8,
                        child: SvgPicture.asset(
                          'assets/images/ic_pet_foot_default.svg',
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 10),
          // Pet Info Text Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title (Name + Primary Star Icon)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600, // SemiBold
                          height: 1.4,
                          letterSpacing: -0.66,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (pet.isPrimary) ...[
                      const SizedBox(width: 4),
                      // Figma Icon/Favorite/24 (금색 원 + 흰 별)
                      SvgPicture.asset(
                        'assets/images/ic_favorite.svg',
                        width: 24,
                        height: 24,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                // 종 · 나이 · 성별 — 다른 화면과 동일한 순서 (검수 15행)
                _buildDescription(),
              ],
            ),
          ),
          if (showActionButton) ...[
            const SizedBox(width: 16), // Figma: 펫 정보 ↔ 버튼 16
            // Edit Button (Outline Button, height 32px)
            OutlinedButton(
              onPressed: onActionPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: AppColors.textMuted, // var(--color/gray/100)
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.dot,
      ),
    );
  }
}
