import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_bootstrap.dart';
import '../../app/app_routes.dart';
import '../../core/storage/token_storage.dart';
import '../../core/widgets/card_banner.dart';
import '../../core/widgets/custom_gnb.dart';
import '../../core/widgets/main_header.dart';
import '../../core/widgets/section_title.dart';
import '../attendance/attendance_screen.dart';
import '../auth/application/auth_providers.dart';
import '../camera/camera_mission_guide_screen.dart';
import '../member/my/my_page_view.dart';
import 'widgets/home_event_carousel.dart';

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
    return Scaffold(
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

class _HomeOverview extends StatelessWidget {
  const _HomeOverview({required this.onOpenCare});

  final VoidCallback onOpenCare;

  @override
  Widget build(BuildContext context) {
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
                title: '출석 체크 리워드',
                subtitle: '매일 출석하고 포인트 받자!',
                pointText: '+100P',
                statusText: '연속 출석',
                dayText: '15일',
                bannerImg: Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEEEBE),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
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
                bannerIcon: const Icon(Icons.local_fire_department, color: Color(0xFFFF5F5F), size: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AttendanceScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              NurimCardBanner(
                title: '마이펫 촬영 리워드',
                subtitle: '귀여운 사진 찍고 포인트 받자!',
                pointText: '+100P',
                pointTextColor: const Color(0xFF85B48B),
                pointBgColor: const Color(0xFFE7FAEA),
                statusText: '이번 주 촬영',
                dayText: '3일 / 7일',
                bannerImg: Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCEFDE),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraMissionGuideScreen()),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
