import 'dart:math' as math;

import 'package:flutter/material.dart';

class NurimPetCardData {
  const NurimPetCardData({
    required this.name,
    required this.breed,
    required this.ageText,
    required this.genderText,
    required this.membershipTier,
    required this.rewardText,
    this.isPrimary = false,
    this.imageProvider,
  });

  final String name;
  final String breed;
  final String ageText;
  final String genderText;
  final String membershipTier;
  final String rewardText;
  final bool isPrimary;
  final ImageProvider? imageProvider;

  String get description => [
    breed,
    ageText,
    genderText,
  ].where((value) => value.trim().isNotEmpty).join(' · ');
}

class NurimPetCard extends StatelessWidget {
  const NurimPetCard({
    super.key,
    required this.pet,
    this.onPressed,
    this.width,
    this.height = 224,
  });

  final NurimPetCardData pet;
  final VoidCallback? onPressed;
  final double? width;
  final double height;

  static const Color _backgroundColor = Colors.white;
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _titleColor = Color(0xFF30343C);
  static const Color _mutedColor = Color(0xFF87909E);
  static const Color _softBackgroundColor = Color(0xFFF7F8FA);
  static const Color _dividerColor = Color(0xFFE8EBF1);
  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _primarySoftColor = Color(0xFFC7B3FF);
  static const Color _primaryBadgeColor = Color(0xFFF4C21B);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PetAvatar(imageProvider: pet.imageProvider),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.66,
                              color: _titleColor,
                            ),
                          ),
                        ),
                        if (pet.isPrimary) ...[
                          const SizedBox(width: 8),
                          const _PrimaryPetBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        letterSpacing: -0.66,
                        color: _mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, size: 38, color: _mutedColor),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _softBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          size: 28,
                          color: _mutedColor,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '멤버십',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              letterSpacing: -0.66,
                              color: _mutedColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _MembershipChip(label: pet.membershipTier),
                      ],
                    ),
                  ),
                  const Divider(height: 17, thickness: 1, color: _dividerColor),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.paid_outlined,
                          size: 28,
                          color: _mutedColor,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '리워드',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              letterSpacing: -0.66,
                              color: _mutedColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          pet.rewardText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: -0.66,
                            color: _titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onPressed == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: card,
      ),
    );
  }
}

class NurimMyPetSection extends StatelessWidget {
  const NurimMyPetSection({
    super.key,
    required this.pets,
    this.onPetPressed,
    this.onAddPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<NurimPetCardData> pets;
  final ValueChanged<NurimPetCardData>? onPetPressed;
  final VoidCallback? onAddPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalInset = _horizontalInsetFor(padding);
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth - horizontalInset
            : 343.0;
        final cardWidth = math.min(343.0, math.max(0.0, availableWidth));
        final visiblePets = pets.isEmpty ? [_emptyPet] : pets;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 224,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: padding,
                physics: const BouncingScrollPhysics(),
                itemCount: visiblePets.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final pet = visiblePets[index];
                  return NurimPetCard(
                    width: cardWidth,
                    pet: pet,
                    onPressed: pets.isEmpty || onPetPressed == null
                        ? null
                        : () => onPetPressed!(pet),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: padding,
              child: _AddPetButton(onPressed: onAddPressed),
            ),
          ],
        );
      },
    );
  }

  static const NurimPetCardData _emptyPet = NurimPetCardData(
    name: '마이 펫',
    breed: '등록된 펫 정보가 없습니다',
    ageText: '',
    genderText: '',
    membershipTier: '-',
    rewardText: '0P',
  );

  static double _horizontalInsetFor(EdgeInsetsGeometry geometry) {
    final edgeInsets = geometry.resolve(TextDirection.ltr);
    return edgeInsets.left + edgeInsets.right;
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.imageProvider});

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 36,
      backgroundColor: const Color(0xFFF0F2F5),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.pets, size: 32, color: NurimPetCard._mutedColor)
          : null,
    );
  }
}

class _PrimaryPetBadge extends StatelessWidget {
  const _PrimaryPetBadge();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 15,
      backgroundColor: NurimPetCard._primaryBadgeColor,
      child: Icon(Icons.star_rounded, size: 18, color: Colors.white),
    );
  }
}

class _MembershipChip extends StatelessWidget {
  const _MembershipChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: NurimPetCard._primarySoftColor, width: 1.5),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1.4,
          letterSpacing: -0.66,
          color: NurimPetCard._primaryColor,
        ),
      ),
    );
  }
}

class _AddPetButton extends StatelessWidget {
  const _AddPetButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: CustomPaint(
          painter: _DashedRoundedRectPainter(
            color: enabled
                ? NurimPetCard._primaryColor
                : NurimPetCard._borderColor,
          ),
          child: SizedBox(
            height: 56,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '마이 펫 추가',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                      letterSpacing: -0.66,
                      color: enabled
                          ? NurimPetCard._titleColor
                          : NurimPetCard._mutedColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.add,
                    size: 26,
                    color: enabled
                        ? NurimPetCard._primaryColor
                        : NurimPetCard._mutedColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({required this.color});

  final Color color;

  static const double _radius = 12;
  static const double _strokeWidth = 1.5;
  static const double _dashLength = 6;
  static const double _gapLength = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(_strokeWidth / 2),
          const Radius.circular(_radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + _dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedRectPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
