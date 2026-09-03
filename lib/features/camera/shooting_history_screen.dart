import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/authed_file_image.dart';
import '../../core/widgets/camera_history_card.dart';
import '../../core/widgets/nurim_refreshable.dart';
import '../../core/widgets/pet_select_card.dart';
import 'camera_screen.dart';
import 'data/photo_event_repository.dart';
import 'domain/photo_event_models.dart';
import '../../core/theme/app_colors.dart';

/// 촬영 내역 화면 (Figma USR-EVT-019)
///
/// [eventMasterId] 와 펫 식별자([petId] 또는 [petData.petId])가 모두 있으면
/// `GET /events/photo/{eventMasterId}/pets/{petId}/history` 를 조회해 실제
/// 참여 횟수·누적 리워드·촬영 목록을 표시한다. 식별자가 없으면 표시용 기본
/// 데이터(빈 상태)를 보여준다.
class ShootingHistoryScreen extends ConsumerWidget {
  const ShootingHistoryScreen({
    super.key,
    this.petData,
    this.eventMasterId,
    this.petId,
  });

  /// 요약 카드에 표시할 펫 정보(품종·나이·성별·썸네일 등). 없으면 기본값 사용.
  final PetSelectCardData? petData;

  /// 촬영 내역 조회에 사용할 이벤트 식별자
  final String? eventMasterId;

  /// 촬영 내역 조회 대상 펫 식별자([petData.petId] 로도 대체 가능)
  final String? petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectivePetId = petId ?? petData?.petId;
    final canQuery = eventMasterId != null &&
        eventMasterId!.isNotEmpty &&
        effectivePetId != null &&
        effectivePetId.isNotEmpty;

    if (canQuery) {
      final historyArg =
          (eventMasterId: eventMasterId!, petId: effectivePetId);
      final historyAsync = ref.watch(photoPetHistoryProvider(historyArg));
      Future<void> refresh() async {
        ref.invalidate(photoPetHistoryProvider(historyArg));
        await ref.read(photoPetHistoryProvider(historyArg).future);
      }
      return historyAsync.when(
        data: (history) => _buildScaffold(
          context,
          cardData: _cardDataFrom(ref, history),
          body: NurimRefreshable(
            onRefresh: refresh,
            child: history.items.isEmpty
                ? RefreshableCenter(
                    child: _EmptyHistoryView(
                      eventMasterId: eventMasterId,
                      petId: effectivePetId,
                      petData: petData,
                    ),
                  )
                : _HistoryList(items: history.items),
          ),
        ),
        loading: () => _buildScaffold(
          context,
          cardData: _cardDataFrom(ref, null),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        error: (_, __) => _buildScaffold(
          context,
          cardData: _cardDataFrom(ref, null),
          body: NurimRefreshable(
            onRefresh: refresh,
            child: RefreshableCenter(
              child: _EmptyHistoryView(
                eventMasterId: eventMasterId,
                petId: effectivePetId,
                petData: petData,
              ),
            ),
          ),
        ),
      );
    }

    // 이벤트/펫 식별자가 없으면 표시용 기본 데이터(빈 상태)
    return _buildScaffold(
      context,
      cardData: _fallbackCardData(),
      body: const _EmptyHistoryView(),
    );
  }

  /// history(있으면) + petData(표시 정보)를 합쳐 요약 카드 데이터를 만든다.
  CameraHistoryCardData _cardDataFrom(WidgetRef ref, PhotoHistory? history) {
    final histFileId = history?.pet?.thumbnailFileId;
    final imageProvider = petData?.imageProvider ??
        (histFileId != null
            ? AuthedFileImageX.of(ref, histFileId, variant: 'thumb')
            : null);
    final name = (petData?.name.isNotEmpty ?? false)
        ? petData!.name
        : (history?.pet?.petName ?? '');
    return CameraHistoryCardData(
      name: name,
      breed: petData?.breed ?? '',
      ageText: petData?.ageText ?? '',
      genderText: petData?.genderText ?? '',
      thisMonthCount: history?.monthParticipationCount ?? 0,
      accumulatedRewards: history?.totalReward ?? 0,
      isFavorite: petData?.isFavorite ?? false,
      imageProvider: imageProvider,
    );
  }

  /// API 조회가 불가능할 때(식별자 없음) 사용하는 표시용 기본 데이터.
  CameraHistoryCardData _fallbackCardData() {
    final display = petData;
    if (display != null) {
      return CameraHistoryCardData(
        name: display.name,
        breed: display.breed,
        ageText: display.ageText,
        genderText: display.genderText,
        thisMonthCount: 0,
        accumulatedRewards: 0,
        isFavorite: display.isFavorite,
        imageProvider: display.imageProvider,
      );
    }
    // 표시할 펫 정보가 전혀 없을 때의 디폴트 (Figma 예시)
    return const CameraHistoryCardData(
      name: '뭉치',
      breed: '시바',
      ageText: '2살',
      genderText: '남아',
      thisMonthCount: 0,
      accumulatedRewards: 0,
      isFavorite: true,
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required CameraHistoryCardData cardData,
    required Widget body,
  }) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.string(_backIconSvg, width: 24, height: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '촬영 내역',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textStrong,
            letterSpacing: -0.54,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.string(_homeIconSvg, width: 24, height: 24),
            onPressed: () {
              // 홈 화면으로 바로 이동 (모든 스택 팝)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480), // 태블릿 가로 늘어남 방지
            child: Column(
              children: [
                // 1. 반려동물 요약 카드 영역 (공통 위젯 사용)
                CameraHistoryCard(data: cardData),

                // 2. 영역 구분선 (6px 회색 띠)
                Container(height: 6, color: AppColors.bgGray),

                // 3. 내역 목록 / 빈 상태 / 로딩
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 촬영 내역 목록 (Figma USR-EVT-019: List header + Camera list)
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.items});

  final List<PhotoHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    // index 0 = 목록 헤더("전체 N" / "최신 내역 순"), 이후 = 내역 행
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _HistoryListHeader(total: items.length);
        return _HistoryItemTile(item: items[index - 1]);
      },
    );
  }
}

/// Figma `List header`(582:10431) — 전체 건수 + 정렬 상태 라벨.
/// 백엔드가 최신순 고정으로만 내려주므로(정렬 파라미터 없음) 라벨은 정적 표기.
class _HistoryListHeader extends StatelessWidget {
  const _HistoryListHeader({required this.total});

  final int total;

  static const TextStyle _label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.66,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('전체', style: _label),
              const SizedBox(width: 4),
              Text('$total',
                  style: _label.copyWith(color: AppColors.textStrong)),
            ],
          ),
          const Text(
            '최신 내역 순',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.66,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 촬영 내역 1건 카드
class _HistoryItemTile extends ConsumerWidget {
  const _HistoryItemTile({required this.item});

  final PhotoHistoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileId = item.imageFileId;
    final image =
        fileId != null ? AuthedFileImageX.of(ref, fileId, variant: 'thumb') : null;

    // Figma `Camera list`(582:10484): 전체폭 + 하단 구분선, 상하 패딩 24
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7.2),
            child: SizedBox(
              width: 48,
              height: 48,
              child: image != null
                  ? Image(
                      image: image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbFallback(),
                    )
                  : _thumbFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '촬영 미션 완료',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    height: 1.4,
                    letterSpacing: -0.66,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.participatedDt),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDisabled,
                    height: 1.4,
                    letterSpacing: -0.66,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16), // Figma: 텍스트 ↔ 리워드 16
          Text(
            '+${item.rewardValue}PR',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.4,
              letterSpacing: -0.66,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _thumbFallback() => Container(
        color: AppColors.bgGray,
        child: const Center(
          child: Icon(Icons.pets, size: 24, color: AppColors.dot),
        ),
      );

  static String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    return dt != null ? dt.toDotDate() : raw;
  }
}

/// 내역이 없을 때 노출되는 빈 플레이스홀더 영역
class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView({this.eventMasterId, this.petId, this.petData});

  final String? eventMasterId;
  final String? petId;

  /// 촬영 화면을 거쳐 내역으로 돌아올 때 요약 카드에 쓸 펫 정보
  final PetSelectCardData? petData;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 문구
          const Text(
            '아직 촬영 내역이 없어요.\n촬영 미션에 참여해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.placeholder, // placeholder 그레이
              letterSpacing: -0.66,
            ),
          ),
          const SizedBox(height: 24),

          // 촬영하기 버튼
          SizedBox(
            width: 283,
            height: 56,
            child: FilledButton(
              onPressed: () {
                // 카메라 촬영 화면으로 이동 (이벤트/펫 정보 전달)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraScreen(
                      eventMasterId: eventMasterId,
                      petId: petId,
                      petData: petData,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary, // 브랜드 퍼플
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.66,
                ),
              ),
              child: const Text('촬영하기'),
            ),
          ),
        ],
      ),
    );
  }
}

// 피그마 원본 Icon/Home/24 벡터 패스 (굴뚝 디테일 포함)
const String _homeIconSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11.3789 4.2666C11.7426 3.97866 12.2574 3.97866 12.6211 4.2666L19.6211 9.80859C19.8605 9.99827 20 10.2873 20 10.5928V19.5C20 20.0523 19.5523 20.5 19 20.5H5C4.44772 20.5 4 20.0523 4 19.5V10.5928C4 10.2873 4.1395 9.99827 4.37891 9.80859L11.3789 4.2666Z" stroke="#51565F" stroke-width="2"/>
  <path d="M13 15C13 14.4477 12.5523 14 12 14C11.4477 14 11 14.4477 11 15L12 15L13 15ZM12 21L13 21L13 15L12 15L11 15L11 21L12 21Z" fill="#51565F"/>
</svg>
''';

// 피그마 원본 Icon/ArrowLeft/24-2 벡터 패스 (긴 뒤로가기 화살표)
const String _backIconSvg = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate(4, 6) rotate(180 3.5 6)">
    <path fill-rule="evenodd" clip-rule="evenodd" d="M0.292893 0.292893C0.683418 -0.0976311 1.31658 -0.0976311 1.70711 0.292893L6.70711 5.29289C7.09763 5.68342 7.09763 6.31658 6.70711 6.70711L1.70711 11.7071C1.31658 12.0976 0.683418 12.0976 0.292893 11.7071C-0.0976311 11.3166 -0.0976311 10.6834 0.292893 10.2929L4.58579 6L0.292893 1.70711C-0.0976311 1.31658 -0.0976311 0.683418 0.292893 0.292893Z" fill="#51565F"/>
  </g>
  <g transform="translate(5, 11)">
    <path fill-rule="evenodd" clip-rule="evenodd" d="M0 1C0 0.447715 0.447715 0 1 0H14C14.5523 0 15 0.447715 15 1C15 1.55228 14.5523 2 14 2H1C0.447715 2 0 1.55228 0 1Z" fill="#51565F"/>
  </g>
</svg>
''';
