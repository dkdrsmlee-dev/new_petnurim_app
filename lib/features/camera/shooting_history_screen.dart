import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/widgets/camera_history_card.dart';
import '../../core/widgets/pet_select_card.dart';
import 'camera_screen.dart';
import '../../core/theme/app_colors.dart';

/// 촬영 내역 화면 (Figma USR-EVT-019)
class ShootingHistoryScreen extends StatelessWidget {
  const ShootingHistoryScreen({
    super.key,
    this.petData,
  });

  /// 펫 정보가 전달되면 해당 정보를 표시하고, 없으면 기본 디폴트 펫(뭉치) 데이터를 보여줍니다.
  final PetSelectCardData? petData;

  @override
  Widget build(BuildContext context) {
    // 디폴트 데이터 세팅 (Figma 디자인 기반)
    final displayData = petData ??
        const PetSelectCardData(
          name: '뭉치',
          breed: '시바',
          ageText: '2살',
          genderText: '남아',
          isFavorite: true,
        );

    // 카드용 데이터 변환
    final cardData = CameraHistoryCardData(
      name: displayData.name,
      breed: displayData.breed,
      ageText: displayData.ageText,
      genderText: displayData.genderText,
      thisMonthCount: 0, // 초기 참여 회수 0회
      accumulatedRewards: 800, // 초기 리워드 800PR
      isFavorite: displayData.isFavorite,
      imageProvider: displayData.imageProvider,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.string(
            _backIconSvg,
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '촬영 내역',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textStrong,
            letterSpacing: -0.54,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.string(
              _homeIconSvg,
              width: 24,
              height: 24,
            ),
            onPressed: () {
              // 홈 화면으로 바로 이동 (모든 스택 팝 후 홈 탭 복귀 등)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480), // 태블릿 가로 늘어남 방지
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight, // 꽉 찬 화면에서 EmptyState를 가운데 배치하기 위함
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // 1. 반려동물 요약 카드 영역 (공통 위젯 사용)
                          CameraHistoryCard(data: cardData),

                          // 2. 영역 구분선 (6px 회색 띠)
                          Container(
                            height: 6,
                            color: AppColors.bgGray,
                          ),

                          // 3. 비어있는 상태 (남은 공간을 모두 차지하도록 구성)
                          const Expanded(
                            child: _EmptyHistoryView(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 내역이 없을 때 노출되는 빈 플레이스홀더 영역
class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

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
              fontFamily: 'Pretendard',
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
                // 카메라 촬영 화면으로 이동
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraScreen(),
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
                  fontFamily: 'Pretendard',
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
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11.3789 3.71573C11.7426 3.42779 12.2574 3.42779 12.6211 3.71573L19.6211 9.25772C19.8605 9.4474 20 9.73645 20 10.0419V18.9491C20 19.5014 19.5523 19.9491 19 19.9491H5C4.44772 19.9491 4 19.5014 4 18.9491V10.0419C4 9.73645 4.1395 9.4474 4.37891 9.25772L11.3789 3.71573Z" stroke="#51565F" stroke-width="2"/>
  <g transform="translate(12, 15)">
    <path d="M2 1C2 0.447715 1.55228 0 1 0C0.447715 0 0 0.447715 0 1H1H2ZM1 7H2V1H1H0V7H1Z" fill="#51565F"/>
  </g>
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
