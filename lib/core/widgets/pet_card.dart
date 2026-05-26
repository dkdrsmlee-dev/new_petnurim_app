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

  List<String> get descriptionList => [
    breed,
    ageText,
    genderText,
  ].map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  String get description => descriptionList.join(' · ');
}

class NurimPetCard extends StatelessWidget {
  const NurimPetCard({
    super.key,
    required this.pet,
    this.onPressed,
    this.width,
    this.height = 204,
  });

  final NurimPetCardData pet;
  final VoidCallback? onPressed;
  final double? width;
  final double height;

  static const Color _backgroundColor = Colors.white;
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _titleColor = Color(0xFF30343C);
  static const Color _nameColor = Color(0xFF51565F);
  static const Color _rewardColor = Color(0xFF30343C);
  static const Color _mutedColor = Color(0xFF909AA9);
  static const Color _softBackgroundColor = Color(0xFFF8F9FB);
  static const Color _dividerColor = Color(0xFFE8EBF1);
  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _primarySoftColor = Color(0xFFC7B3FF);
  static const Color _primaryBadgeColor = Color(0xFFF4C21B);

  Widget _buildDescription() {
    final list = pet.descriptionList;
    if (list.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      children.add(
        Flexible(
          child: Text(
            list[i],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.66,
              color: Color(0xFF909AA9),
            ),
          ),
        ),
      );
      if (i < list.length - 1) {
        children.add(const SizedBox(width: 4));
        children.add(const _DotSeparator());
        children.add(const SizedBox(width: 4));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PetAvatar(imageProvider: pet.imageProvider),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              letterSpacing: -0.66,
                              color: _nameColor,
                            ),
                          ),
                        ),
                        if (pet.isPrimary) ...[
                          const SizedBox(width: 4),
                          const _PrimaryPetBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildDescription(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF909AA9),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _softBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const _CrownIcon(
                        size: 20,
                        color: Color(0xFF87909E),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          '멤버십',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            letterSpacing: -0.66,
                            color: Color(0xFF87909E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _MembershipChip(label: pet.membershipTier),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 1, color: _dividerColor),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const _CoinStackIcon(
                        size: 20,
                        color: Color(0xFF87909E),
                        bgColor: _softBackgroundColor,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          '리워드',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            letterSpacing: -0.66,
                            color: Color(0xFF87909E),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          letterSpacing: -0.66,
                          color: _rewardColor,
                        ),
                      ),
                    ],
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
        borderRadius: BorderRadius.circular(16),
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
            : 320.0;
        final cardWidth = math.min(320.0, math.max(0.0, availableWidth));
        final visiblePets = pets.isEmpty ? [_emptyPet] : pets;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 204,
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

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Color(0xFFB4C0D3),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.imageProvider});

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFF0F2F5),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.pets, size: 24, color: NurimPetCard._mutedColor)
          : null,
    );
  }
}

class _PrimaryPetBadge extends StatelessWidget {
  const _PrimaryPetBadge();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 12,
      backgroundColor: NurimPetCard._primaryBadgeColor,
      child: Icon(Icons.star_rounded, size: 16, color: Colors.white),
    );
  }
}

class _MembershipChip extends StatelessWidget {
  const _MembershipChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFFF),
        border: Border.all(color: const Color(0xFFC6BAFF)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2,
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
            height: 40,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '마이 펫 추가',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.66,
                      color: enabled
                          ? NurimPetCard._primaryColor
                          : NurimPetCard._mutedColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.add,
                    size: 16,
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

class _CrownIcon extends StatelessWidget {
  const _CrownIcon({this.size = 20, this.color = NurimPetCard._mutedColor});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CrownPainter(color: color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double w = size.width;
    final double h = size.height;

    path.moveTo(4, h - 3);
    path.lineTo(w - 4, h - 3);
    path.lineTo(w - 3, h * 0.45);
    path.lineTo(w * 0.78, h * 0.22);
    path.lineTo(w * 0.62, h * 0.6);
    path.lineTo(w * 0.5, h * 0.12);
    path.lineTo(w * 0.38, h * 0.6);
    path.lineTo(w * 0.22, h * 0.22);
    path.lineTo(3, h * 0.45);
    path.close();

    path.moveTo(4, h - 7);
    path.lineTo(w - 4, h - 7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => color != oldDelegate.color;
}

class _CoinStackIcon extends StatelessWidget {
  const _CoinStackIcon({
    this.size = 20,
    this.color = NurimPetCard._mutedColor,
    this.bgColor = NurimPetCard._softBackgroundColor,
  });
  final double size;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CoinStackPainter(color: color, bgColor: bgColor),
    );
  }
}

class _CoinStackPainter extends CustomPainter {
  const _CoinStackPainter({required this.color, required this.bgColor});
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;
    final double cw = w * 0.65;
    final double ch = h * 0.22;
    final double thick = h * 0.16;

    final List<double> centersY = [
      h * 0.72,
      h * 0.50,
      h * 0.28,
    ];

    for (final cy in centersY) {
      final bodyPath = Path()
        ..addOval(Rect.fromCenter(center: Offset(w / 2, cy), width: cw, height: ch))
        ..moveTo(w / 2 - cw / 2, cy)
        ..lineTo(w / 2 - cw / 2, cy + thick)
        ..arcTo(Rect.fromCenter(center: Offset(w / 2, cy + thick), width: cw, height: ch), math.pi, -math.pi, false)
        ..lineTo(w / 2 + cw / 2, cy)
        ..close();
      canvas.drawPath(bodyPath, fillPaint);

      canvas.drawArc(
        Rect.fromCenter(center: Offset(w / 2, cy + thick), width: cw, height: ch),
        0,
        math.pi,
        false,
        strokePaint,
      );

      canvas.drawLine(
        Offset(w / 2 - cw / 2, cy),
        Offset(w / 2 - cw / 2, cy + thick),
        strokePaint,
      );
      canvas.drawLine(
        Offset(w / 2 + cw / 2, cy),
        Offset(w / 2 + cw / 2, cy + thick),
        strokePaint,
      );

      canvas.drawOval(
        Rect.fromCenter(center: Offset(w / 2, cy), width: cw, height: ch),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CoinStackPainter oldDelegate) {
    return color != oldDelegate.color || bgColor != oldDelegate.bgColor;
  }
}
