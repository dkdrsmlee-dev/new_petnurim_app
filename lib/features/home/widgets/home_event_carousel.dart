import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/authed_file_image.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../event/data/event_repository.dart';
import '../../event/domain/event_models.dart';

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

// ⛳️ ─────────────────────────────────────────────────────────────
// MILESTONE: 홈 배너 소스 전환 스위치
//   true  = 백엔드 이벤트 배너 API 사용 (GET /api/v1/events/banners)
//   false = 기존 하드코딩 배너 3종으로 복귀 (_LegacyBannerCarousel)
//   → 하드코딩 배너로 되돌리려면 이 값만 false 로 바꾸세요.
//     (레거시 코드는 아래 _LegacyBannerCarousel 에 그대로 보존되어 있음)
//   [2026-07-24] homeBanners 는 홈 상단 슬라이더용 데이터가 아님이 확인되어
//                false 로 되돌림. 원래 하드코딩 배너 사용.
// ─────────────────────────────────────────────────────────────────
const bool _useApiBanners = false;

class HomeEventCarousel extends StatelessWidget {
  const HomeEventCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return _useApiBanners
        ? const _ApiBannerCarousel()
        : const _LegacyBannerCarousel();
  }
}

// ═══════════════════════════════════════════════════════════════════
// 신규: 백엔드 이벤트 배너 API 기반 캐러셀
// ═══════════════════════════════════════════════════════════════════
class _ApiBannerCarousel extends ConsumerStatefulWidget {
  const _ApiBannerCarousel();

  @override
  ConsumerState<_ApiBannerCarousel> createState() => _ApiBannerCarouselState();
}

class _ApiBannerCarouselState extends ConsumerState<_ApiBannerCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9413);
  }

  @override
  void dispose() {
    _stopTimer();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentIndex + 1) % count;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// bannerFile → ImageProvider (fileUrl 절대URL 우선, 없으면 fileId 인증 다운로드)
  ImageProvider? _bannerImage(BannerFile? file) {
    if (file == null) return null;
    final url = file.fileUrl;
    if (url != null &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return NetworkImage(url);
    }
    final id = file.fileId;
    if (id != null && id.isNotEmpty) {
      // 배너는 203px 표시라 원본 대신 medium 축소본 사용(다운로드 속도 개선).
      // medium 이 없으면(404 등) 원본 다운로드로 자동 폴백.
      return AuthedFileImageX.of(ref, id, variant: 'medium', downloadFallback: true);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(homeBannersProvider);
    return bannersAsync.when(
      loading: () => _buildPlaceholder(),
      error: (e, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        // 데이터 도착 후 자동 스크롤 시작 (개수 반영, 중복 시작 방지)
        if (_isPlaying && _timer == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startTimer(banners.length);
          });
        }
        return SizedBox(
          height: 203,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              if (_isPlaying) _startTimer(banners.length);
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _buildBannerCard(banners[index], banners.length),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 203,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const ShimmerBox(),
    );
  }

  Widget _buildBannerCard(EventBanner banner, int total) {
    final image = _bannerImage(banner.bannerFile);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 백엔드 제공 배너 이미지
          if (image != null)
            Image(
              image: image,
              fit: BoxFit.cover,
              // 로딩 중 셔머 → 로드 완료 시 이미지로 교체
              frameBuilder: shimmerImageFrameBuilder,
              errorBuilder: (context, error, stack) => _buildImageFallback(banner),
            )
          else
            _buildImageFallback(banner),

          // 재생/정지 + 페이지 인디케이터 오버레이 (기존 디자인 유지)
          Positioned(
            right: 10,
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                      if (_isPlaying) {
                        _startTimer(total);
                      } else {
                        _stopTimer();
                      }
                    });
                  },
                  child: Container(
                    width: 21,
                    height: 21,
                    decoration: const BoxDecoration(
                      color: Color(0x99000000),
                      shape: BoxShape.circle,
                    ),
                    child: _isPlaying
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 2, height: 8, color: Colors.white),
                              const SizedBox(width: 2),
                              Container(width: 2, height: 8, color: Colors.white),
                            ],
                          )
                        : const Icon(Icons.play_arrow,
                            size: 11, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
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
                          text: '/ ${total < 10 ? '0$total' : '$total'}',
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

  /// 배너 이미지가 없거나 로딩 실패 시 이벤트명 표시
  Widget _buildImageFallback(EventBanner banner) {
    return Container(
      color: AppColors.bgGray,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        banner.eventName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 레거시: 하드코딩 배너 3종 — _useApiBanners = false 일 때 사용 (보존)
// ═══════════════════════════════════════════════════════════════════
class _LegacyBannerCarousel extends StatefulWidget {
  const _LegacyBannerCarousel();

  @override
  State<_LegacyBannerCarousel> createState() => _LegacyBannerCarouselState();
}

class _LegacyBannerCarouselState extends State<_LegacyBannerCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;
  bool _isPlaying = true;

  final List<_BannerData> _banners = [
    _BannerData(
      bgColor: const Color(0xFFEDEFFE),
      badgeText: '친구초대 이벤트',
      titleLine1: '친구랑 같이',
      titleLine2: '리워드 받아요!',
      subtitle: '초대할수록 혜택이 쌓여요!',
      titleColor: AppColors.textStrong,
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

  // 홈 상단에 노출할 배너: 현재는 첫 번째(01번) 하나만 표시.
  // (나머지 배너 정의는 위에 보존 — 여러 개 노출로 되돌리려면 take 수만 조정)
  late final List<_BannerData> _visibleBanners = _banners.take(1).toList();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9413);
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_visibleBanners.length <= 1) return; // 단일 배너면 자동 슬라이드 없음
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentIndex + 1) % _visibleBanners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
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
          if (_isPlaying) {
            _startTimer();
          }
        },
        itemCount: _visibleBanners.length,
        itemBuilder: (context, index) {
          final banner = _visibleBanners[index];
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
                    color: AppColors.primary,
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
                    color: AppColors.textSecondary,
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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                      if (_isPlaying) {
                        _startTimer();
                      } else {
                        _stopTimer();
                      }
                    });
                  },
                  child: Container(
                    width: 21,
                    height: 21,
                    decoration: const BoxDecoration(
                      color: Color(0x99000000), // rgba(0,0,0,0.6)
                      shape: BoxShape.circle,
                    ),
                    child: _isPlaying
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 2, height: 8, color: Colors.white),
                              const SizedBox(width: 2),
                              Container(width: 2, height: 8, color: Colors.white),
                            ],
                          )
                        : const Icon(
                            Icons.play_arrow,
                            size: 11,
                            color: Colors.white,
                          ),
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
                          text: '/ 0${_visibleBanners.length}',
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
