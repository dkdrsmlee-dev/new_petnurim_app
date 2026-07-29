import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_bootstrap.dart';
import '../../app/app_routes.dart';
import '../../core/storage/token_storage.dart';
import '../../core/widgets/card_banner.dart';
import '../../core/widgets/custom_gnb.dart';
import '../../core/widgets/main_header.dart';
import '../../core/widgets/section_title.dart';
import '../../core/utils/toast_util.dart';
import '../attendance/attendance_screen.dart';
import '../auth/application/auth_providers.dart';
import '../event/data/event_repository.dart';
import '../../core/widgets/authed_file_image.dart';
import '../camera/camera_mission_guide_screen.dart';
import '../member/my/my_page_view.dart';
import 'widgets/home_event_carousel.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.initialTab,
  });

  final int? initialTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _selectedIndex;
  bool _isLoggingOut = false;
  DateTime? _lastBackPressedAt; // 홈에서 '뒤로 두 번 종료' 판정용

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab ?? 0;
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null && widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _selectedIndex = widget.initialTab!;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 시스템 백을 항상 가로채서 직접 처리 (하위 탭→홈 / 홈→두 번 눌러 종료)
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // 홈 탭이 아니면(마이페이지 등) 홈 탭으로 복귀 (상단 <- 와 동일)
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }
        // 홈 탭: 2초 내 두 번 누르면 종료, 아니면 안내 토스트
        final now = DateTime.now();
        if (_lastBackPressedAt != null &&
            now.difference(_lastBackPressedAt!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPressedAt = now;
        ToastUtil.show(context, '한 번 더 누르면 종료됩니다.');
      },
      child: Scaffold(
        appBar: _selectedIndex == 5
            ? null
            : MainHeader(
                onTapProfile: () {
                  setState(() {
                    _selectedIndex = 5;
                  });
                },
              ),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _HomeOverview(onOpenCare: () => setState(() => _selectedIndex = 2)),
              const _GiftTabView(),
              const _CareTabView(),
              const _PetTabView(),
              const _EventTabView(),
              MyPageView(
                isLoggingOut: _isLoggingOut,
                onLogout: _logout,
                onBackToHome: () => setState(() => _selectedIndex = 0),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomGnb(
          currentIndex: _selectedIndex >= 5 ? -1 : _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .logout()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // 서버 로그아웃 실패/지연 시에도 로컬 로그아웃은 계속 진행 (best-effort)
    }
    await ref.read(tokenStorageProvider).clearTokens();
    ref.invalidate(appBootstrapStateProvider);

    if (!mounted) {
      return;
    }

    context.go(AppRoutes.authStart);
  }
}

class _HomeOverview extends ConsumerWidget {
  const _HomeOverview({required this.onOpenCare});

  final VoidCallback onOpenCare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 이벤트 템플릿(출석/촬영)으로 리워드 카드 구성
    final templates = ref.watch(eventTemplatesProvider).value;
    final attendance = templates?.attendance;
    final photo = templates?.photo;
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 28),
      children: [
        const HomeEventCarousel(),
        const SizedBox(height: 32),
        const NurimSectionTitle(
          title: '매일 받는 리워드 혜택',
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              NurimCardBanner(
                title: attendance?.title ?? '출석 체크 리워드',
                subtitle: '매일 출석하고 포인트 받자!',
                pointText: '+${attendance?.defaultReward?.rewardValue ?? 100}P',
                statusText: '연속 출석',
                dayText: attendance != null
                    ? '${attendance.continuousAttendanceDays}일'
                    : '-일',
                bannerImg: _rewardThumb(
                  ref,
                  attendance?.thumbnailFileId,
                  const Color(0xFFFEEEBE),
                  Stack(
                    children: [
                      Positioned(
                        left: 39 + 10.01 - (77.332 / 2),
                        top: 39 - 12.44 - (79.802 / 2),
                        width: 77.332,
                        height: 79.802,
                        child: Image.asset(
                          'assets/images/home/card_img_1.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                bannerIcon: const Icon(Icons.local_fire_department, color: AppColors.errorSoft, size: 20),
                onTap: attendance == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttendanceScreen(
                              eventMasterId: attendance.eventMasterId,
                            ),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 10),
              NurimCardBanner(
                title: photo?.title ?? '마이펫 촬영 리워드',
                subtitle: '귀여운 사진 찍고 포인트 받자!',
                pointText: '+${photo?.defaultReward?.rewardValue ?? 100}P',
                pointTextColor: const Color(0xFF85B48B),
                pointBgColor: const Color(0xFFE7FAEA),
                statusText: '이번 주 촬영',
                dayText: '3일 / 7일',
                bannerImg: _rewardThumb(
                  ref,
                  photo?.thumbnailFileId,
                  const Color(0xFFDCEFDE),
                  Stack(
                    children: [
                      Positioned(
                        left: 39 + 19.5 - (77.033 / 2),
                        top: 39 + 6.77 - (54.544 / 2),
                        width: 77.033,
                        height: 54.544,
                        child: Transform.scale(
                          scaleX: -1, // -scale-y-100 + rotate-180 = horizontal flip
                          child: Image.asset(
                            'assets/images/home/card_img_2.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bannerIcon: const Icon(Icons.camera_alt, color: Color(0xFF85B48B), size: 20), // Figma has IconCamera20 but camera_alt is a good fallback
                onTap: photo == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraMissionGuideScreen(
                              eventMasterId: photo.eventMasterId,
                            ),
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 리워드 카드 썸네일: 이벤트 thumbnail(fileId) 로드, 없거나 실패 시 기본 일러스트로 폴백
Widget _rewardThumb(
  WidgetRef ref,
  String? fileId,
  Color bg,
  Widget fallback,
) {
  final provider = (fileId != null && fileId.isNotEmpty)
      ? AuthedFileImageX.of(ref, fileId, variant: 'thumb')
      : null;
  return Container(
    width: 78,
    height: 78,
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    clipBehavior: Clip.hardEdge,
    child: provider == null
        ? fallback
        : Image(
            image: provider,
            width: 78,
            height: 78,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          ),
  );
}



class _CareTabView extends StatelessWidget {
  const _CareTabView();

  @override
  Widget build(BuildContext context) {
    return const _ListPage(
      title: '진료 관리',
      description: '예약, 문진, 진료 내역을 확인합니다.',
      items: [
        _ListItem(
          icon: Icons.event_note_outlined,
          title: '예약 일정',
          subtitle: '예정된 진료 일정',
        ),
        _ListItem(
          icon: Icons.edit_note_outlined,
          title: '문진 작성',
          subtitle: '방문 전 상태 기록',
        ),
        _ListItem(
          icon: Icons.history_outlined,
          title: '진료 내역',
          subtitle: '이전 진료 기록',
        ),
      ],
    );
  }
}

class _PetTabView extends StatelessWidget {
  const _PetTabView();

  @override
  Widget build(BuildContext context) {
    return const _ListPage(
      title: '반려동물',
      description: '반려동물 프로필과 건강 기록을 관리합니다.',
      items: [
        _ListItem(
          icon: Icons.add_circle_outline,
          title: '프로필 등록',
          subtitle: '이름, 품종, 생일',
        ),
        _ListItem(
          icon: Icons.monitor_heart_outlined,
          title: '건강 기록',
          subtitle: '체중과 주요 증상',
        ),
        _ListItem(
          icon: Icons.vaccines_outlined,
          title: '접종 관리',
          subtitle: '예방접종 기록',
        ),
      ],
    );
  }
}

class _ListPage extends StatelessWidget {
  const _ListPage({
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<_ListItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(description),
        const SizedBox(height: 18),
        for (final item in items) ...[item, const SizedBox(height: 10)],
      ],
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: subtitle.isEmpty ? 16 : 14,
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _GiftTabView extends StatelessWidget {
  const _GiftTabView();

  @override
  Widget build(BuildContext context) {
    return const _ListPage(
      title: '기프트 쇼핑',
      description: '반려동물을 위한 다양한 선물을 만나보세요.',
      items: [
        _ListItem(
          icon: Icons.shopping_bag_outlined,
          title: '스토어',
          subtitle: '추천 선물 목록',
        ),
        _ListItem(
          icon: Icons.confirmation_number_outlined,
          title: '쿠폰함',
          subtitle: '나의 보유 쿠폰',
        ),
      ],
    );
  }
}

class _EventTabView extends StatelessWidget {
  const _EventTabView();

  @override
  Widget build(BuildContext context) {
    return const _ListPage(
      title: '이벤트',
      description: '진행 중인 다양한 이벤트와 혜택을 확인하세요.',
      items: [
        _ListItem(
          icon: Icons.card_giftcard_outlined,
          title: '출석 체크',
          subtitle: '매일매일 룰렛 돌리기',
        ),
        _ListItem(
          icon: Icons.campaign_outlined,
          title: '친구 초대',
          subtitle: '함께 하고 포인트 받기',
        ),
      ],
    );
  }
}
