import 'package:flutter/material.dart';
import '../../core/widgets/camera_history_card.dart';
import '../../core/widgets/pet_select_card.dart';
import 'camera_screen.dart';

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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF30343C),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '촬영 내역',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF30343C),
            letterSpacing: -0.54,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.home_outlined,
              size: 24,
              color: Color(0xFF30343C),
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
                            color: const Color(0xFFF4F6F8),
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
              color: Color(0xFFA2ADBE), // placeholder 그레이
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
                backgroundColor: const Color(0xFF7F4FFF), // 브랜드 퍼플
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
