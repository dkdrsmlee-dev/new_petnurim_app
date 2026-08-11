import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/authed_file_image.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../event/data/event_repository.dart';
import '../../event/domain/event_models.dart';

// ⛳️ ─────────────────────────────────────────────────────────────
// MILESTONE: 홈 배너 소스 전환 스위치
//   true  = 백엔드 이벤트 배너 API 사용 (GET /api/v1/events/banners)
//   false = 디자인 친구초대 배너(_DesignFriendBanner) 사용
//   [2026-08-06] 홈 리디자인(Figma 116:8397)으로 배너를 디자인 레이아웃(보라 배경
//                + 친구 일러스트 + 하단 중앙 텍스트 + dot)으로 교체. 레거시 하드코딩
//                캐러셀은 제거하고, 백엔드 배너 캐러셀(_ApiBannerCarousel)은 보존.
// ─────────────────────────────────────────────────────────────────
const bool _useApiBanners = false;

class HomeEventCarousel extends StatelessWidget {
  const HomeEventCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return _useApiBanners
        ? const _ApiBannerCarousel()
        : const _DesignFriendBanner();
  }
}

// ═══════════════════════════════════════════════════════════════════
// 백엔드 이벤트 배너 API 기반 캐러셀 (_useApiBanners = true 일 때 사용, 보존)
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
      return AuthedFileImageX.of(ref, id,
          variant: 'medium', downloadFallback: true);
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
              errorBuilder: (context, error, stack) =>
                  _buildImageFallback(banner),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
// 디자인 친구초대 배너 (Figma 116:8430) — 보라 배경 + 3D 친구 일러스트 +
// 하단 그라데이션·중앙 텍스트 + dot. 디자인 프레임 폭 343 기준 좌표를
// 실제 폭에 비례 스케일(f)해 배치한다.
// ═══════════════════════════════════════════════════════════════════
class _DesignFriendBanner extends StatelessWidget {
  const _DesignFriendBanner();

  static const String _p = 'assets/images/home';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 친구초대(이벤트) 배너는 아직 백엔드 미연동 → 탭 시 준비 중 토스트.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ToastUtil.show(context, '준비 중인 기능입니다.'),
            child: LayoutBuilder(
              builder: (context, constraints) => _card(constraints.maxWidth),
            ),
          ),
          const SizedBox(height: 16),
          // 페이저(현재 배너 1개 → 활성 dot 1개). 배너 추가 시 개수 반영.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _Dot(active: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(double w) {
    final f = w / 343; // 디자인 프레임 폭
    final h = 313 * f;

    Positioned at(
      double x,
      double y,
      double bw,
      double bh,
      Widget child, {
      double deg = 0,
    }) {
      return Positioned(
        left: x * f,
        top: y * f,
        width: bw * f,
        height: bh * f,
        child: deg == 0
            ? child
            : Transform.rotate(angle: deg * math.pi / 180, child: child),
      );
    }

    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF9673FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 하단 그라데이션(텍스트 가독성) — 콘텐츠 뒤
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 135 * f,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x66000000)],
                ),
              ),
            ),
          ),
          // 배경 스월(상단), 180° 회전
          Positioned(
            left: 0,
            top: 0,
            width: 343 * f,
            height: 253.142 * f,
            child: Transform.rotate(
              angle: math.pi,
              child: SvgPicture.asset('$_p/banner_swirl.svg', fit: BoxFit.fill),
            ),
          ),
          // 캐릭터 아래 플랫폼(글로우)
          at(53.5, 108, 242, 107,
              SvgPicture.asset('$_p/banner_union.svg', fit: BoxFit.fill)),
          // 친구 캐릭터 (가운데, top 20)
          Positioned(
            left: (343 / 2 - 164 / 2) * f,
            top: 20 * f,
            width: 164 * f,
            height: 177 * f,
            child: Image.asset('$_p/banner_friends.png', fit: BoxFit.contain),
          ),
          // 반짝이·별
          at(39.06, 123.57, 8.442, 8.442,
              SvgPicture.asset('$_p/banner_ellipse.svg')), // Ellipse 346 (노란 점)
          at(273 - 15.059 / 2, 98.5 - 13.804 / 2, 15.059, 13.804,
              SvgPicture.asset('$_p/banner_sparkle1.svg'),
              deg: 20.19),
          at(84.2 - 9, 49.7 - 9, 18, 18,
              SvgPicture.asset('$_p/banner_sparkle2.svg'),
              deg: 11.24),
          at(263.55, 66.96, 8.417, 9.311,
              SvgPicture.asset('$_p/banner_star2.svg')),
          at(64.9, 108.1, 8.5, 8.6,
              SvgPicture.asset('$_p/banner_deco.svg')),
          at(294.9, 108.1, 8.5, 8.6,
              SvgPicture.asset('$_p/banner_deco.svg')),
          // 텍스트 (하단 중앙)
          Positioned(
            left: 0,
            right: 0,
            bottom: 20 * f,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '친구 초대하고\n함께 리워드 받아요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '초대할수록 쌓이는 혜택을 누려보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: Color(0xFFB4C0D3),
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

/// 배너 하단 페이저 dot(6px). 활성=보라, 비활성=회색.
class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
