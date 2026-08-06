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
import '../../core/widgets/nurim_refreshable.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/utils/toast_util.dart';
import '../../core/widgets/edge_button_dialog.dart';
import '../../core/widgets/pet_select_card.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/attendance_pet_select_screen.dart';
import '../auth/application/auth_providers.dart';
import '../member/data/pet_repository.dart';
import '../member/domain/pet_codes.dart';
import '../member/domain/pet_models.dart';
import '../event/data/event_repository.dart';
import '../../core/widgets/authed_file_image.dart';
import '../camera/camera_mission_guide_screen.dart';
import '../member/my/my_page_view.dart';
import 'home_image_preloader.dart';
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
    // 홈 이미지(배너·리워드 썸네일·출석/촬영 상세)를 백그라운드로 미리 받아둔다.
    // 신규 로그인/새로고침 경로 커버(토큰복원 콜드 진입은 스플래시에서 이미 워밍).
    ref.watch(homeImagePrewarmProvider);
    return ColoredBox(
      color: AppColors.bgGray,
      child: NurimRefreshable(
      onRefresh: () async {
        ref.invalidate(eventTemplatesProvider);
        await ref.read(eventTemplatesProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
        // 상단 흰색 블록(배너) — 하단 라운드로 회색 미션 시트가 올라오는 효과
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
          ),
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          child: const HomeEventCarousel(),
        ),
        // 매일 받는 리워드 미션 (Figma 116:8397) — 회색 배경 위 2열 컴팩트 카드
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '매일 받는 리워드 미션',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: NurimCardBannerSmall(
                      width: double.infinity,
                      titleLine1: '매일 출석하고',
                      titleLine2: '포인트 받기',
                      pointText:
                          '+${attendance?.defaultReward?.rewardValue ?? 100}P',
                      statusText: '연속 출석',
                      dayText: attendance != null
                          ? '${attendance.continuousAttendanceDays}일'
                          : '-일',
                      bannerImg: _missionAvatar(
                        ref,
                        attendance?.thumbnailFileId,
                        const Color(0xFF7FD3F2),
                        'assets/images/home/mission_char_att.png',
                        33.4,
                        47.9,
                        8.1,
                      ),
                      onTap: attendance == null
                          ? null
                          : () => _onAttendanceTap(
                                context,
                                ref,
                                attendance.eventMasterId,
                              ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: NurimCardBannerSmall(
                      width: double.infinity,
                      titleLine1: '마이펫 사진 찍고',
                      titleLine2: '리워드 받기',
                      pointText:
                          '+${photo?.defaultReward?.rewardValue ?? 100}P',
                      statusText: '주간 참여',
                      dayText: '3',
                      daySuffix: ' / 7일',
                      bannerImg: _missionAvatar(
                        ref,
                        photo?.thumbnailFileId,
                        const Color(0xFFEEBEF5),
                        'assets/images/home/mission_char_cam.png',
                        30.0,
                        50.2,
                        7.4,
                      ),
                      onTap: photo == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CameraMissionGuideScreen(
                                    eventMasterId: photo.eventMasterId,
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
      ),
      ),
    );
  }

  /// 출석 카드 탭 → 등록 펫 수에 따라 분기(사진 이벤트와 동일 패턴).
  /// 0마리: 등록 안내 다이얼로그 / 1마리: 바로 출석 화면 / 2마리+: 펫 선택 화면.
  Future<void> _onAttendanceTap(
    BuildContext context,
    WidgetRef ref,
    String eventMasterId,
  ) async {
    List<MyPetListItem> pets;
    try {
      final res =
          await ref.read(petRepositoryProvider).getMyPetsList(limit: 100);
      pets = res.items;
    } catch (_) {
      if (context.mounted) {
        ToastUtil.show(context, '펫 정보를 불러오지 못했습니다. 다시 시도해 주세요.');
      }
      return;
    }
    if (!context.mounted) return;

    final cards = pets
        .map(
          (item) => PetSelectCardData(
            petId: item.myPetId,
            name: item.petName,
            breed: (item.breedNameKor != null && item.breedNameKor!.isNotEmpty)
                ? item.breedNameKor!
                : '믹스',
            ageText: '${item.petAge}살',
            genderText:
                PetGender.label(item.genderCode, serverName: item.genderCodeNm),
            isFavorite: YesNo.isYes(item.representYn),
            imageProvider: item.profileFileId != null
                ? AuthedFileImageX.of(ref, item.profileFileId!, variant: 'thumb')
                : null,
          ),
        )
        .toList();

    if (cards.isEmpty) {
      // 0마리: 마이펫 등록 안내 다이얼로그
      final router = GoRouter.of(context);
      showDialog(
        context: context,
        builder: (_) => EdgeButtonDialog(
          title: '아이 등록이 필요해요.',
          content: '아이 등록 후 리워드 이벤트에\n참여할 수 있어요.',
          cancelText: '닫기',
          confirmText: '마이펫 등록',
          onConfirm: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            router.push(AppRoutes.myPetAdd);
          },
        ),
      );
    } else if (cards.length == 1) {
      // 1마리: 바로 출석 화면
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceScreen(
            eventMasterId: eventMasterId,
            myPetId: cards.first.petId!,
          ),
        ),
      );
    } else {
      // 2마리 이상: 펫 선택 화면
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendancePetSelectScreen(
            pets: cards,
            eventMasterId: eventMasterId,
          ),
        ),
      );
    }
  }
}

/// 미션 카드 아바타: 색 원 안에 **백엔드 이벤트 썸네일**(thumbnailFileId)을 넣고,
/// 없거나 로드 실패 시 디자인 캐릭터([fallbackAsset])로 폴백한다.
/// [charW]/[charH]는 폴백 캐릭터 표시 크기(50px 원 안), [top]은 상단 오프셋.
Widget _missionAvatar(
  WidgetRef ref,
  String? fileId,
  Color bg,
  String fallbackAsset,
  double charW,
  double charH,
  double top,
) {
  final Widget fallback = Stack(
    children: [
      Positioned(
        top: top,
        left: (50 - charW) / 2,
        width: charW,
        height: charH,
        child: Image.asset(fallbackAsset, fit: BoxFit.contain),
      ),
    ],
  );
  // 이벤트 썸네일: 작은 'thumb' variant 우선, 서버에 없으면(404 등) 원본 폴백.
  final provider = (fileId != null && fileId.isNotEmpty)
      ? AuthedFileImageX.of(ref, fileId, variant: 'thumb', downloadFallback: true)
      : null;
  return Container(
    width: 50,
    height: 50,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
    child: provider == null
        ? fallback
        : Image(
            image: provider,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            frameBuilder: shimmerImageFrameBuilder,
            errorBuilder: (_, _, _) => fallback,
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
