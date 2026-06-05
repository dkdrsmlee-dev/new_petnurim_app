import 'package:flutter/material.dart';

class NurimCardBanner extends StatelessWidget {
  const NurimCardBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pointText,
    required this.statusText,
    required this.dayText,
    this.bannerImg,
    this.bannerIcon,
    this.onTap,
    this.width,
    this.pointTextColor,
    this.pointBgColor,
  });

  final String title;
  final String subtitle;
  final String pointText;
  final String statusText;
  final String dayText;
  final Widget? bannerImg;
  final Widget? bannerIcon;
  final VoidCallback? onTap;
  final double? width;
  final Color? pointTextColor;
  final Color? pointBgColor;

  static const Color _backgroundColor = Colors.white;
  static const Color _borderColor = Color(0xFFF4F6F8);
  static const Color _titleColor = Color(0xFF30343C);
  static const Color _subtitleColor = Color(0xFF87909E);
  static const Color _pointTextColor = Color(0xFFC0A858);
  static const Color _pointBgColor = Color(0xFFFFFAE0);
  static const Color _statusBarBgColor = Color(0xFFF8F9FB);
  static const Color _statusTextColor = Color(0xFF51565F);
  static const Color _dayTextColor = Color(0xFF30343C);

  @override
  Widget build(BuildContext context) {
    final Widget cardContent = Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A51565F), // rgba(81, 86, 95, 0.1)
            offset: Offset(0, 0),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.66,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: -0.66,
                        color: _subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pointBgColor ?? _pointBgColor,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        pointText,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          letterSpacing: -0.66,
                          color: pointTextColor ?? _pointTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              bannerImg ??
                  Container(
                    width: 78,
                    height: 78,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7DE),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.card_giftcard,
                        color: Color(0xFFC0A858),
                        size: 32,
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _statusBarBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: bannerIcon ??
                          const Icon(
                            Icons.local_fire_department,
                            color: Color(0xFFFF5F5F),
                            size: 20,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: -0.66,
                        color: _statusTextColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  dayText,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: _dayTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return cardContent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: cardContent,
      ),
    );
  }
}

/// Card_banne2 (피그마 오타 그대로) 에 해당하는 소형 세로 배너 카드.
/// 165 × 174 크기의 컴팩트 카드로, 가로 스크롤 목록 등에 사용됩니다.
class NurimCardBannerSmall extends StatelessWidget {
  const NurimCardBannerSmall({
    super.key,
    required this.titleLine1,
    required this.titleLine2,
    required this.pointText,
    required this.statusText,
    required this.dayText,
    this.bannerImg,
    this.onTap,
    this.width = 165,
    this.height = 174,
  });

  final String titleLine1;
  final String titleLine2;
  final String pointText;
  final String statusText;
  final String dayText;
  final Widget? bannerImg;
  final VoidCallback? onTap;
  final double width;
  final double height;

  static const Color _backgroundColor = Colors.white;
  static const Color _borderColor = Color(0xFFF4F6F8);
  static const Color _titleColor = Color(0xFF30343C);
  static const Color _pointBadgeBorderColor = Color(0xFFD6DBE4);
  static const Color _pointTextColor = Color(0xFF6C737F);
  static const Color _statusBarBgColor = Color(0xFFF4F6F8);
  static const Color _statusTextColor = Color(0xFF87909E);
  static const Color _dayTextColor = Color(0xFF30343C);

  @override
  Widget build(BuildContext context) {
    final Widget cardContent = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A51565F), // rgba(81, 86, 95, 0.1)
            offset: Offset(0, 0),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 이미지 + 포인트 배지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bannerImg ??
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7FD3F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: _pointBadgeBorderColor),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  pointText,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: _pointTextColor,
                  ),
                ),
              ),
            ],
          ),

          // 중단: 2줄 타이틀 + 화살표
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleLine1,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titleLine2,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.66,
                        color: _titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: _titleColor,
                  ),
                ],
              ),
            ],
          ),

          // 하단: 상태 바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _statusBarBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: _statusTextColor,
                  ),
                ),
                Text(
                  dayText,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: _dayTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return cardContent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      ),
    );
  }
}
