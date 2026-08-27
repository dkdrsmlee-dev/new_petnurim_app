import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
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
    this.onMembershipJoinTap,
  });

  final String name;
  final String breed;
  final String ageText;
  final String genderText;
  final String membershipTier;
  final String rewardText;
  final bool isPrimary;
  final ImageProvider? imageProvider;

  /// "멤버십 가입하기" 칩(미가입) 탭 시 동작(혜택 화면 이동). 미가입일 때만 사용.
  final VoidCallback? onMembershipJoinTap;

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
    this.showSelectionControl = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  final NurimPetCardData pet;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final bool showSelectionControl;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;

  static const Color _backgroundColor = Colors.white;

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
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.66,
              color: AppColors.textDisabled,
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
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSelectionControl) ...[
            GestureDetector(
              onTap: onSelectionChanged,
              child: Container(
                width: 21,
                height: 21,
                margin: const EdgeInsets.only(top: 13.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1.05,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPressed,
                  child: Row(
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
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
                            const SizedBox(height: 4),
                            _buildDescription(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Figma Icon/ArrowRight/24
                      SvgPicture.asset(
                        'assets/images/ic_arrow_right_24.svg',
                        width: 24,
                        height: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            // Figma Icon/Crown/20
                            SvgPicture.asset(
                              'assets/images/ic_crown_20.svg',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                '멤버십',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  letterSpacing: -0.66,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _MembershipChip(
                              label: pet.membershipTier,
                              onTap: pet.onMembershipJoinTap,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Figma Icon/Coin/20 (ic_coin.svg와 동일 지오메트리, 회색 #51565F)
                            SvgPicture.asset(
                              'assets/images/ic_coin_20.svg',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                '리워드',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  letterSpacing: -0.66,
                                  color: AppColors.textSecondary,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: -0.66,
                                color: AppColors.textStrong,
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
          ),
        ],
      ),
    );

    return card;
  }
}

class NurimMyPetSection extends StatefulWidget {
  const NurimMyPetSection({
    super.key,
    required this.pets,
    this.onPetPressed,
    this.onAddPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.viewportFraction = 0.9,
  });

  final List<NurimPetCardData> pets;
  final ValueChanged<NurimPetCardData>? onPetPressed;
  final VoidCallback? onAddPressed;
  final EdgeInsetsGeometry padding;
  final double viewportFraction;

  @override
  State<NurimMyPetSection> createState() => _NurimMyPetSectionState();
}

class _NurimMyPetSectionState extends State<NurimMyPetSection> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 기존 0.85에서 기본값 0.90으로 변경하여 좌우 크기를 키웠습니다.
    _pageController = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void didUpdateWidget(covariant NurimMyPetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportFraction != widget.viewportFraction) {
      _pageController.dispose();
      _pageController = PageController(viewportFraction: widget.viewportFraction);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pets.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 80,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '등록된 펫 정보가 없어요.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: AppColors.placeholder,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '펫 정보를 등록해 주세요 :)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: widget.padding,
            child: _AddPetButton(onPressed: widget.onAddPressed),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 204,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.pets.length,
            itemBuilder: (context, index) {
              final pet = widget.pets[index];
              return Padding(
                // 뷰포트 간 간격을 만들기 위해 양쪽에 8px씩 패딩을 줍니다 (총 간격 16px)
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: NurimPetCard(
                  width: double.infinity, // PageView가 너비를 제어하므로 최대 확장
                  pet: pet,
                  onPressed: widget.onPetPressed == null
                      ? null
                      : () => widget.onPetPressed!(pet),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: widget.padding,
          child: _AddPetButton(onPressed: widget.onAddPressed),
        ),
      ],
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
        color: AppColors.dot,
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
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF0F2F5),
      ),
      child: imageProvider != null
          ? Image(
              image: imageProvider!,
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
    );
  }
}

class _MembershipChip extends StatelessWidget {
  const _MembershipChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isJoinPrompt = label == '멤버십 가입하기';
    final isNone = label == '-';

    final chip = Container(
      width: isNone ? 24 : null,
      height: 24,
      padding: isNone ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: isJoinPrompt ? 6 : 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isJoinPrompt ? Colors.white : AppColors.primarySurface,
        border: Border.all(color: const Color(0xFFC6BAFF)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.66,
              color: AppColors.primary,
            ),
          ),
          if (isJoinPrompt) ...[
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );

    // "멤버십 가입하기" 칩만 탭 가능(혜택 화면 이동). 브론즈 배지는 비탭.
    if (isJoinPrompt && onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: chip,
      );
    }
    return chip;
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
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _DashedRoundedRectPainter(
              color: enabled
                  ? AppColors.border
                  : AppColors.borderLight,
            ),
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      '마이 펫 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        letterSpacing: -0.66,
                        color: enabled
                            ? AppColors.textStrong
                            : AppColors.textDisabled,
                      ),
                    ),
                    Text(
                      ' +',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        letterSpacing: -0.66,
                        color: enabled
                            ? AppColors.primary
                            : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
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
