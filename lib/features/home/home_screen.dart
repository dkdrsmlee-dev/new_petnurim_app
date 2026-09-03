import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
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
import '../member/data/pet_repository.dart';
import '../member/domain/pet_codes.dart';
import '../member/domain/pet_models.dart';
import '../event/data/event_repository.dart';
import '../event/data/mission_refresh_providers.dart';
import '../event/domain/event_models.dart';
import '../../core/widgets/authed_file_image.dart';
import '../camera/camera_mission_guide_screen.dart';
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
  DateTime? _lastBackPressedAt; // 홈에서 '뒤로 두 번 종료' 판정용

  // 홈 탭은 0~4(홈/기프트/문진/경품메타/이벤트)만 존재한다. 마이페이지는 별도
  // 라우트라 tab 인덱스로 오지 않지만, 방어적으로 범위를 벗어난 값은 홈(0)으로.
  int _clampTab(int? tab) => (tab != null && tab >= 0 && tab <= 4) ? tab : 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _clampTab(widget.initialTab);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null && widget.initialTab != oldWidget.initialTab) {
      setState(() {
        _selectedIndex = _clampTab(widget.initialTab);
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
        appBar: MainHeader(
          // 마이페이지는 홈 탭이 아니라 별도 라우트로 push한다(GNB 미표시).
          onTapProfile: () => context.push(AppRoutes.myPage),
          onTapNotification: () => context.push(AppRoutes.notificationCenter),
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
            ],
          ),
        ),
        bottomNavigationBar: CustomGnb(
          currentIndex: _selectedIndex,
          onTap: (index) {
            // 홈 외 탭(기프트/문진/경품메타/이벤트)은 준비 중 — 토스트만, 화면 이동 없음.
            if (index != 0) {
              ToastUtil.show(context, '준비 중인 기능입니다.');
              return;
            }
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
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
    // 미션 완료 직후 홈 수치를 확정값/낙관값으로 즉시 표시하기 위한 override(①).
    // override가 있으면 templates 집계 지연과 무관하게 그 값을 보여준다.
    final missionOverride = ref.watch(homeMissionOverrideProvider);
    final attendanceDays =
        missionOverride.attendanceDays ?? attendance?.continuousAttendanceDays;
    final participationCount =
        missionOverride.participationCount ?? photo?.participationCount;
    // 홈 이미지(배너·리워드 썸네일·출석/촬영 상세)를 백그라운드로 미리 받아둔다.
    // 신규 로그인/새로고침 경로 커버(토큰복원 콜드 진입은 스플래시에서 이미 워밍).
    ref.watch(homeImagePrewarmProvider);
    return ColoredBox(
      color: AppColors.bgGray,
      child: NurimRefreshable(
      onRefresh: () async {
        ref.invalidate(eventTemplatesProvider);
        await ref.read(eventTemplatesProvider.future);
        // 수동 새로고침은 최신 집계이므로 임시 override를 걷어낸다.
        ref
            .read(homeMissionOverrideProvider.notifier)
            .set(const HomeMissionOverride());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
        // 상단 흰색 블록(배너)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          child: const HomeEventCarousel(),
        ),
        // 매일 받는 리워드 미션 (Figma content 116:8398)
        // 회색 시트가 상단 라운드(14)로 흰 배너 아래에 얹히는 형태.
        // 바깥 ColoredBox가 라운드 뒤로 비치는 흰색을 깔아 곡률이 드러난다.
        ColoredBox(
          color: Colors.white,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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
                        dayText:
                            attendanceDays != null ? '$attendanceDays일' : '-일',
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: NurimCardBannerSmall(
                        width: double.infinity,
                        titleLine1: '마이펫 사진 찍고',
                        titleLine2: '리워드 받기',
                        pointText:
                            '+${photo?.defaultReward?.rewardValue ?? 100}P',
                        statusText: '주간 참여',
                        // 사진 미션 주간 참여 횟수(백엔드 participationCount, 비로그인 0)
                        dayText:
                            participationCount != null ? '$participationCount' : '-',
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
                            : () async {
                                // 이번 촬영 플로우의 결과만 반영되도록 이전 신호를 비운다.
                                ref
                                    .read(photoParticipatedProvider.notifier)
                                    .set(null);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CameraMissionGuideScreen(
                                      eventMasterId: photo.eventMasterId,
                                    ),
                                  ),
                                );
                                // 미션 완료 후 홈 복귀 시 주간참여 최신화(①/②+③).
                                if (!context.mounted) return;
                                final participatedPetId =
                                    ref.read(photoParticipatedProvider);
                                ref
                                    .read(photoParticipatedProvider.notifier)
                                    .set(null);
                                await _afterPhoto(
                                  ref,
                                  context,
                                  participatedPetId,
                                );
                              },
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

    // 홈 "연속 출석"은 대표펫 기준 → 대표펫으로 출석했을 때만 override 적용.
    final representPetId = _representPetId(pets);
    // 이번 출석 플로우의 결과만 반영되도록 이전 신호를 비운다.
    ref.read(attendanceCheckResultProvider.notifier).set(null);

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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendanceScreen(
            eventMasterId: eventMasterId,
            myPetId: cards.first.petId!,
          ),
        ),
      );
      // 출석 완료 후 홈 복귀 시 연속출석 최신화(①+③).
      if (context.mounted) await _afterAttendance(ref, context, representPetId);
    } else {
      // 2마리 이상: 펫 선택 화면
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendancePetSelectScreen(
            pets: cards,
            eventMasterId: eventMasterId,
          ),
        ),
      );
      if (context.mounted) await _afterAttendance(ref, context, representPetId);
    }
  }
}

/// 펫 목록에서 대표펫의 id를 찾는다(없으면 null).
String? _representPetId(List<MyPetListItem> pets) {
  for (final p in pets) {
    if (YesNo.isYes(p.representYn)) return p.myPetId;
  }
  return null;
}

/// 출석 완료 후 홈 복귀 시 "연속 출석"을 최신화한다.
/// 출석 화면이 발행한 확정값([attendanceCheckResultProvider])을 소비하되,
/// **대표펫으로 출석했을 때만** 홈(대표 기준) 수치를 즉시 갱신하고 폴링한다(①+③).
Future<void> _afterAttendance(
  WidgetRef ref,
  BuildContext context,
  String? representPetId,
) async {
  final sig = ref.read(attendanceCheckResultProvider);
  ref.read(attendanceCheckResultProvider.notifier).set(null); // 소비 후 리셋
  if (sig != null && representPetId != null && sig.petId == representPetId) {
    await _reconcileMission(
      ref,
      context,
      attendanceTarget: sig.continuousAttendanceDays,
    );
  } else {
    // 미출석 또는 비대표펫 출석: 홈 수치는 불변 → 일반 재조회만.
    ref.invalidate(eventTemplatesProvider);
  }
}

/// 촬영 참여 후 홈 복귀 시 "주간 참여"를 최신화한다.
/// **대표펫으로 참여했을 때만** 홈(대표 기준)을 +1 낙관 갱신 후 폴링한다(①/②+③).
Future<void> _afterPhoto(
  WidgetRef ref,
  BuildContext context,
  String? participatedPetId,
) async {
  if (participatedPetId == null) {
    // 참여 없이 돌아온 경우: 일반 재조회만.
    ref.invalidate(eventTemplatesProvider);
    return;
  }
  // 참여한 펫이 대표펫인지 확인(홈 주간참여는 대표펫 기준).
  String? representPetId;
  try {
    final res = await ref.read(petRepositoryProvider).getMyPetsList(limit: 100);
    representPetId = _representPetId(res.items);
  } catch (_) {
    representPetId = null;
  }
  if (!context.mounted) return;
  if (representPetId != null && participatedPetId == representPetId) {
    final cur =
        ref.read(eventTemplatesProvider).value?.photo?.participationCount ?? 0;
    await _reconcileMission(ref, context, photoTarget: cur + 1);
  } else {
    // 비대표펫 참여(또는 대표 확인 실패): 홈 수치 불변 → 일반 재조회만.
    ref.invalidate(eventTemplatesProvider);
  }
}

/// 미션 완료 후 홈 수치 재조정(①+③).
/// - ① 목표값([attendanceTarget]/[photoTarget])을 override로 즉시 표시
/// - ③ `/events/templates`가 목표값에 도달할 때까지 짧게 폴링 → 도달한 필드만 해제
///   (지연이 폴링 창을 넘겨도 확정값을 계속 노출하므로 stale 0이 보이지 않는다)
Future<void> _reconcileMission(
  WidgetRef ref,
  BuildContext context, {
  int? attendanceTarget,
  int? photoTarget,
}) async {
  final notifier = ref.read(homeMissionOverrideProvider.notifier);
  // ① 즉시 확정값 override(제공된 필드만 설정, 나머지는 유지).
  final before = ref.read(homeMissionOverrideProvider);
  notifier.set(HomeMissionOverride(
    attendanceDays: attendanceTarget ?? before.attendanceDays,
    participationCount: photoTarget ?? before.participationCount,
  ));

  // ③ 집계가 목표값에 도달할 때까지 폴링.
  const maxAttempts = 5;
  const interval = Duration(milliseconds: 500);
  EventTemplates? latest;
  for (var i = 0; i < maxAttempts; i++) {
    if (!context.mounted) return; // 홈 이탈 시 중단
    ref.invalidate(eventTemplatesProvider);
    try {
      latest = await ref.read(eventTemplatesProvider.future);
    } catch (_) {
      latest = null; // 조회 실패 시 다음 시도
    }
    final attReached = attendanceTarget == null ||
        (latest?.attendance?.continuousAttendanceDays ?? -1) >=
            attendanceTarget;
    final photoReached = photoTarget == null ||
        (latest?.photo?.participationCount ?? -1) >= photoTarget;
    if (attReached && photoReached) break;
    if (i < maxAttempts - 1) await Future.delayed(interval);
  }

  if (!context.mounted) return;
  // 도달한 필드만 override 해제(미도달 필드는 확정값을 계속 노출).
  final cur = ref.read(eventTemplatesProvider).value;
  final s = ref.read(homeMissionOverrideProvider);
  notifier.set(HomeMissionOverride(
    attendanceDays: (attendanceTarget != null &&
            (cur?.attendance?.continuousAttendanceDays ?? -1) >=
                attendanceTarget)
        ? null
        : s.attendanceDays,
    participationCount: (photoTarget != null &&
            (cur?.photo?.participationCount ?? -1) >= photoTarget)
        ? null
        : s.participationCount,
  ));
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
  // 피그마 banner_img(132:9671)는 50 원 안에 캐릭터를 charW×charH 크기로
  // top 만큼 내려 배치한다. 백엔드 썸네일도 같은 기하를 써야 하므로
  // 배치를 헬퍼로 공유한다(예전엔 썸네일만 cover로 원을 꽉 채워 확대돼 보였다).
  Widget place(Widget child) => Stack(
        children: [
          Positioned(
            top: top,
            left: (50 - charW) / 2,
            width: charW,
            height: charH,
            child: child,
          ),
        ],
      );
  final Widget fallbackImage = Image.asset(fallbackAsset, fit: BoxFit.contain);
  // 이벤트 썸네일: 작은 'thumb' variant 우선, 서버에 없으면(404 등) 원본 폴백.
  final provider = (fileId != null && fileId.isNotEmpty)
      ? AuthedFileImageX.of(ref, fileId, variant: 'thumb', downloadFallback: true)
      : null;
  return Container(
    width: 50,
    height: 50,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
    child: place(
      provider == null
          ? fallbackImage
          : Image(
              image: provider,
              fit: BoxFit.contain,
              frameBuilder: shimmerImageFrameBuilder,
              // place()가 이미 감싸고 있으므로 에셋만 반환한다.
              errorBuilder: (_, _, _) => fallbackImage,
            ),
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
