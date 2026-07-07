import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

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

  static const Color _titleColor = Color(0xFF51565F); // var(--text-color/primary)
  static const Color _mutedColor = Color(0xFF909AA9); // var(--color/gray/70)
  static const Color _dotColor = Color(0xFFB4C0D3); // var(--color/gray/50)
  static const Color _borderColor = Color(0xFFD6DBE4); // var(--line/default)
  static const Color _badgeColor = Color(0xFFF4C21B);

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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0F2F5),
              border: Border.all(color: _borderColor, width: 1),
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
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          fontWeight: FontWeight.w600, // SemiBold
                          height: 1.4,
                          letterSpacing: -0.66,
                          color: _titleColor,
                        ),
                      ),
                    ),
                    if (pet.isPrimary) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        color: _badgeColor,
                        size: 24,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                // Description (Age · Breed · Gender)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pet.ageText.isNotEmpty) ...[
                      Text(
                        pet.ageText,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w500, // Medium
                          height: 1.4,
                          letterSpacing: -0.66,
                          color: _mutedColor,
                        ),
                      ),
                    ],
                    if (pet.ageText.isNotEmpty && pet.breed.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      const _DotSeparator(),
                      const SizedBox(width: 4),
                    ],
                    if (pet.breed.isNotEmpty) ...[
                      Text(
                        pet.breed,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.66,
                          color: _mutedColor,
                        ),
                      ),
                    ],
                    if (pet.breed.isNotEmpty && pet.genderText.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      const _DotSeparator(),
                      const SizedBox(width: 4),
                    ],
                    if (pet.genderText.isNotEmpty) ...[
                      Text(
                        pet.genderText,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.66,
                          color: _mutedColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (showActionButton) ...[
            const SizedBox(width: 12),
            // Edit Button (Outline Button, height 32px)
            OutlinedButton(
              onPressed: onActionPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _borderColor, width: 1),
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
                  fontFamily: 'Pretendard',
                  fontSize: 14,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Color(0xFF51565F), // var(--color/gray/100)
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
        color: NurimPetInfoDetail._dotColor,
      ),
    );
  }
}
