import 'package:flutter/material.dart';
import 'dart:math' as math;

class _BannerData {
  final Color bgColor;
  final String badgeText;
  final String titleLine1;
  final String titleLine2;
  final String subtitle;
  final Color titleColor;
  final Widget Function(BuildContext)? customIllustration;

  const _BannerData({
    required this.bgColor,
    required this.badgeText,
    required this.titleLine1,
    required this.titleLine2,
    required this.subtitle,
    required this.titleColor,
    this.customIllustration,
  });
}

class HomeEventCarousel extends StatefulWidget {
  const HomeEventCarousel({super.key});

  @override
  State<HomeEventCarousel> createState() => _HomeEventCarouselState();
}

class _HomeEventCarouselState extends State<HomeEventCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  final List<_BannerData> _banners = [
    _BannerData(
      bgColor: const Color(0xFFEDEFFE),
      badgeText: '친구초대 이벤트',
      titleLine1: '친구랑 같이',
      titleLine2: '리워드 받아요!',
      subtitle: '초대할수록 혜택이 쌓여요!',
      titleColor: const Color(0xFF30343C),
      customIllustration: (context) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 263.76,
              top: 41.75,
              width: 10.25,
              height: 10.25,
              child: Image.asset('assets/images/home/banner_star.png'),
            ),
            Positioned(
              left: 187.4,
              top: 66.75,
              width: 47.2,
              height: 91.5,
              child: Image.asset('assets/images/home/banner_character_2.png'),
            ),
            Positioned(
              left: 235.72,
              top: 46.86,
              width: 83.3,
              height: 111.5,
              child: Image.asset('assets/images/home/banner_character_1.png'),
            ),
            Positioned(
              left: 220.58,
              top: 16.87,
              width: 24.4,
              height: 24.4,
              child: Transform.rotate(
                angle: -7.22 * math.pi / 180,
                child: Image.asset('assets/images/home/banner_coin.png'),
              ),
            ),
          ],
        );
      },
    ),
    const _BannerData(
      bgColor: Color(0xFF0FCB7E),
      badgeText: '신규가입 혜택',
      titleLine1: '첫 펫 등록하면',
      titleLine2: '웰컴 기프트 증정!',
      subtitle: '지금 바로 펫누림과 시작하세요',
      titleColor: Colors.white,
    ),
    const _BannerData(
      bgColor: Color(0xFF22324C),
      badgeText: '제휴 이벤트',
      titleLine1: '펫 용품 할인전',
      titleLine2: '최대 50% 특가',
      subtitle: '펫누림 회원 전용 시크릿 혜택',
      titleColor: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9413);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 203,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _buildBannerCard(banner, context),
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(_BannerData banner, BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: banner.bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 공통 우측 일러스트 배경 원
          Positioned(
            left: 167,
            top: 24,
            child: Container(
              width: 156,
              height: 156,
              decoration: const BoxDecoration(
                color: Color(0xFFE3E6FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // 커스텀 일러스트 이미지들
          if (banner.customIllustration != null)
            Positioned.fill(
              child: banner.customIllustration!(context),
            ),

          Positioned(
            left: 20,
            top: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F4FFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    banner.badgeText,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.4,
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${banner.titleLine1}\n${banner.titleLine2}',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: banner.titleColor,
                    letterSpacing: -0.66,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  banner.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: Color(0xFF87909E),
                    letterSpacing: -0.66,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 10,
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pause button
                Container(
                  width: 21,
                  height: 21,
                  decoration: const BoxDecoration(
                    color: Color(0x99000000), // rgba(0,0,0,0.6)
                    shape: BoxShape.circle,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 2, height: 8, color: Colors.white),
                      const SizedBox(width: 2),
                      Container(width: 2, height: 8, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 6), // gap-[6px]
                // Paging indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '0${_currentIndex + 1} ',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.66,
                          ),
                        ),
                        TextSpan(
                          text: '/ 0${_banners.length}',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFBFBFBF),
                            letterSpacing: -0.66,
                          ),
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
  }
}
