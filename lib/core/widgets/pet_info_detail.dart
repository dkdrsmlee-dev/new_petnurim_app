import 'package:flutter/material.dart';

import 'pet_card.dart';

class NurimPetInfoDetail extends StatelessWidget {
  const NurimPetInfoDetail({
    super.key,
    required this.pet,
    this.actionLabel = '관리',
    this.onPressed,
    this.onActionPressed,
    this.enabled = true,
    this.padding = EdgeInsets.zero,
  });

  final NurimPetCardData pet;
  final String actionLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onActionPressed;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  static const Color _titleColor = Color(0xFF30343C);
  static const Color _mutedColor = Color(0xFF87909E);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _disabledColor = Color(0xFFA2ADBE);
  static const Color _badgeColor = Color(0xFFF4C21B);

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            _PetInfoAvatar(imageProvider: pet.imageProvider),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                            letterSpacing: -0.66,
                            color: enabled ? _titleColor : _disabledColor,
                          ),
                        ),
                      ),
                      if (pet.isPrimary) ...[
                        const SizedBox(width: 4),
                        const _PetInfoPrimaryBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _detailText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      letterSpacing: -0.66,
                      color: enabled ? _mutedColor : _disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _PetInfoActionButton(
              label: actionLabel,
              onPressed: enabled ? onActionPressed : null,
              enabled: enabled,
            ),
          ],
        ),
      ),
    );

    if (onPressed == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: enabled ? onPressed : null, child: content),
    );
  }

  String get _detailText {
    return [
      pet.ageText,
      pet.breed,
      pet.genderText,
    ].where((value) => value.trim().isNotEmpty).join(' · ');
  }
}

class _PetInfoAvatar extends StatelessWidget {
  const _PetInfoAvatar({required this.imageProvider});

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFF0F2F5),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(
              Icons.pets,
              size: 18,
              color: NurimPetInfoDetail._mutedColor,
            )
          : null,
    );
  }
}

class _PetInfoPrimaryBadge extends StatelessWidget {
  const _PetInfoPrimaryBadge();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 9,
      backgroundColor: NurimPetInfoDetail._badgeColor,
      child: Icon(Icons.star_rounded, size: 11, color: Colors.white),
    );
  }
}

class _PetInfoActionButton extends StatelessWidget {
  const _PetInfoActionButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onPressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: effectiveEnabled ? onPressed : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 42),
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: enabled
                ? NurimPetInfoDetail._borderColor
                : const Color(0xFFE8EBF1),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.66,
            color: enabled
                ? NurimPetInfoDetail._titleColor
                : NurimPetInfoDetail._disabledColor,
          ),
        ),
      ),
    );
  }
}
