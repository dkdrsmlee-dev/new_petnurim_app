import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/widgets/popup_header.dart';
import '../../core/widgets/bullit_text.dart';
import '../../core/widgets/pet_select_card.dart';
import 'camera_screen.dart';
import 'pet_empty_screen.dart';
import 'pet_select_screen.dart';
import '../../core/theme/app_colors.dart';

class CameraMissionGuideScreen extends StatelessWidget {
  const CameraMissionGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray, // var(--color/gray/20)
      appBar: PopupHeader(
        title: '마이 펫 촬영',
        showBackButton: false,
        onClosePressed: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 블루 비주얼 및 미션 카드/버튼 영역 (Figma USR-EVT-016 본문 전체)
            Container(
              width: double.infinity,
              color: const Color(0xFF5B64EA), // Figma 파란색배경
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 그라데이션 동그라미 데코레이션 1 (Figma Ellipse 1595)
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 325,
                    top: 267.25,
                    child: SvgPicture.asset(
                      'assets/images/banner/ellipse1595.svg',
                      width: 650,
                      height: 360,
                      fit: BoxFit.fill,
                    ),
                  ),
                  // 그라데이션 동그라미 데코레이션 2 (Figma Ellipse 1593)
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 225.5,
                    top: -10.6,
                    child: SvgPicture.asset(
                      'assets/images/banner/ellipse1593.svg',
                      width: 451,
                      height: 451,
                      fit: BoxFit.fill,
                    ),
                  ),

                  // 본문 콘텐츠 리스트 (수직 플로우)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 34), // Figma top-[34px]

                        // A. 타이틀 배지 및 일러스트 그래픽 영역 (반응형 스케일링 적용)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double screenWidth = MediaQuery.of(context).size.width;
                            final double s = screenWidth / 375; // 기준 해상도 375px 대비 스케일 비율
                            final double cx = screenWidth / 2; // 화면 중앙 X
                            return SizedBox(
                              height: 330 * s,
                              width: double.infinity,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  // ----------------------------------------------------
                                  // I. 배경 일러스트 레이어 (배지 뒤에 위치하는 요소들)
                                  // ----------------------------------------------------

                                  // 1. 카메라 (Figma Node 327:12193)
                                  Positioned(
                                    left: cx - 187.5 * s + 119.1 * s,
                                    top: 178.67 * s,
                                    width: 143.21 * s,
                                    height: 128.65 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -5.39 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/camera1.png',
                                          width: 132.83 * s,
                                          height: 116.68 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 2. 강아지 (Figma Node 327:12194)
                                  Positioned(
                                    left: cx - 187.5 * s + 90.04 * s,
                                    top: 223.63 * s,
                                    width: 49.82 * s,
                                    height: 62.39 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -2.45 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/dog11.png',
                                          width: 47.28 * s,
                                          height: 60.43 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 3. 고양이 (Figma Node 327:12195)
                                  Positioned(
                                    left: cx - 187.5 * s + 232.41 * s,
                                    top: 201.22 * s,
                                    width: 62.82 * s,
                                    height: 63.29 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -24.02 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/cat41.png',
                                          width: 47.28 * s,
                                          height: 48.22 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 4. 동전 5 (Figma Node 551:6819)
                                  Positioned(
                                    left: cx - 187.5 * s + 102.65 * s,
                                    top: 184.78 * s,
                                    width: 26.17 * s,
                                    height: 27.1 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -30.5 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/coin51.png',
                                          width: 18.14 * s,
                                          height: 20.76 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 5. 동전 4 (Figma Node 551:6844)
                                  Positioned(
                                    left: cx - 187.5 * s + 219.84 * s,
                                    top: 269.3 * s,
                                    width: 43.45 * s,
                                    height: 45.59 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: 22.84 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/coin42.png',
                                          width: 31.98 * s,
                                          height: 36.0 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 6. 꽃 8 (Figma Node 338:12544)
                                  Positioned(
                                    left: cx - 187.5 * s + 93.92 * s,
                                    top: 298.61 * s,
                                    width: 14.43 * s,
                                    height: 14.62 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: 28.87 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/flower8.png',
                                          width: 10.44 * s,
                                          height: 10.94 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 7. 꽃 7 (Figma Node 338:12545)
                                  Positioned(
                                    left: cx - 187.5 * s + 77.9 * s,
                                    top: 291.67 * s,
                                    width: 14.72 * s,
                                    height: 15.65 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -11.55 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/flower7.png',
                                          width: 12.27 * s,
                                          height: 13.47 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 8. 꽃 6 (Figma Node 338:12546)
                                  Positioned(
                                    left: cx - 187.5 * s + 303.21 * s,
                                    top: 206.27 * s,
                                    width: 11.71 * s,
                                    height: 12.12 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: 20.94 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/flower6.png',
                                          width: 8.87 * s,
                                          height: 9.59 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 9. 데코레이션 원형 1591 (Figma Node 338:12549)
                                  Positioned(
                                    left: cx - 187.5 * s + 299.1 * s,
                                    top: 282.16 * s,
                                    width: 1.8 * s,
                                    height: 1.8 * s,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),

                                  // 10. 데코레이션 원형 1592 (Figma Node 338:12550)
                                  Positioned(
                                    left: cx - 187.5 * s + 320.68 * s,
                                    top: 198.29 * s,
                                    width: 3.6 * s,
                                    height: 3.6 * s,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),

                                  // 11. 데코레이션 원형 1590 (Figma Node 484:26023)
                                  Positioned(
                                    left: cx - 187.5 * s + 78.62 * s,
                                    top: 188.21 * s,
                                    width: 2.7 * s,
                                    height: 2.7 * s,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),

                                  // 12. 그린 플러스 Union 1 (Figma Node 338:12559)
                                  Positioned(
                                    left: cx - 187.5 * s + 52.1 * s,
                                    top: 209.01 * s,
                                    width: 10.8 * s,
                                    height: 10.8 * s,
                                    child: SvgPicture.asset(
                                      'assets/images/banner/union_plus_1.svg',
                                      width: 10.8 * s,
                                      height: 10.8 * s,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF79FFAE),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),

                                  // 13. 그린 플러스 Union 2 (Figma Node 338:12560)
                                  Positioned(
                                    left: cx - 187.5 * s + 283.49 * s,
                                    top: 288.8 * s,
                                    width: 8.04 * s,
                                    height: 8.04 * s,
                                    child: SvgPicture.asset(
                                      'assets/images/banner/union_plus_2.svg',
                                      width: 8.04 * s,
                                      height: 8.04 * s,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF79FFAE),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),

                                  // ----------------------------------------------------
                                  // II. 중간 타이틀 배지 레이어 (중간 높이)
                                  // ----------------------------------------------------

                                  // 14. 하단 배지 (리워드 받아요!)
                                  Positioned(
                                    top: 97.25 * s,
                                    child: Transform.rotate(
                                      angle: -4.6 * (3.14159 / 180),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 6 * s),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF423F99).withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(9999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              offset: const Offset(2, 4),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '리워드 받아요!',
                                          style: TextStyle(
                                            fontFamily: 'Gmarket Sans',
                                            fontSize: 32 * s,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.96 * s,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 15. 상단 배지 (마이 펫 촬영하고)
                                  Positioned(
                                    top: 34 * s,
                                    child: Transform.rotate(
                                      angle: 2.58 * (3.14159 / 180),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 6 * s),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C83EE),
                                          borderRadius: BorderRadius.circular(9999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              offset: const Offset(2, 4),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '마이 펫 촬영하고',
                                          style: TextStyle(
                                            fontFamily: 'Gmarket Sans',
                                            fontSize: 32 * s,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.96 * s,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // ----------------------------------------------------
                                  // III. 전경 일러스트 레이어 (배지 위에 위치하는 요소)
                                  // ----------------------------------------------------

                                  // 16. 하트 벌룬 (Figma Node 484:25976 - 배지 위로 올라와야 함)
                                  Positioned(
                                    left: cx - 187.5 * s + 248.0 * s,
                                    top: 141.96 * s,
                                    width: 23.81 * s,
                                    height: 22.19 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: 15.62 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/heart2.png',
                                          width: 19.84 * s,
                                          height: 17.49 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // C. 보상 안내 및 기간 텍스트
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF3F7FF),
                              letterSpacing: -0.66,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(text: '미션 수행 시 매일 '),
                              TextSpan(
                                text: '100PR ',
                                style: TextStyle(color: Color(0xFFFF8FE7)),
                              ),
                              TextSpan(text: '지급!'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '2026.4.1~4.30',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF3F7FF),
                            letterSpacing: -0.66,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 30), // 텍스트 ~ 미션 카드 간격 (Figma 30px)

                        // D. 오늘의 수행 미션 카드 (Mission Box)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                offset: const Offset(0, 4),
                                blurRadius: 6,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                offset: const Offset(0, 0),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // "오늘의 수행 미션" 뱃지
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.bgGray,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: const Text(
                                  '오늘의 수행 미션',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                    letterSpacing: -0.66,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // 타이틀: "송곳니를 촬영해 주세요!"
                              const Text(
                                '송곳니를 촬영해 주세요!',
                                style: TextStyle(
                                  fontFamily: 'Gmarket Sans',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: -0.66,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // 이미지 예시 카드 영역
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 92,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final parentWidth = constraints.maxWidth;
                                          final imgSize = 358.069;
                                          final leftPos = (parentWidth - imgSize) / 2 - 7.47;
                                          final topPos = (92 - imgSize) / 2 - 22.61;
                                          return Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Positioned(
                                                left: leftPos,
                                                top: topPos,
                                                width: imgSize,
                                                height: imgSize,
                                                child: Image.asset(
                                                  'assets/images/banner/fangs_guide.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  // 촬영 예시 빨간 뱃지
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorSoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '촬영 예시',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: -0.66,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // 설명 텍스트
                              const Text(
                                '마이 펫의 송곳니 부분이 잘 보이도록\n선명하게 촬영해 주세요.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                  letterSpacing: -0.66,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40), // 미션 카드 ~ 참여 버튼 간격 (Figma 40px)

                        // E. 미션 참여하기 버튼
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x4D47287C), // rgba(71, 40, 124, 0.3)
                                offset: const Offset(0, 4),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _onMissionParticipate(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textStrong, // Figma 검정/진회색 배경
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            child: const Text(
                              '미션 참여하기',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.66,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40), // 버튼 ~ 블루 영역 하단 여백
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. 이벤트 유의사항 섹션 (회색 배경)
            Container(
              width: double.infinity,
              color: AppColors.bgGray, // var(--color/gray/20)
              padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이벤트 유의사항',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: -0.66,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const BullitText(
                    text: '미션 수행 시 100PR이 즉시 지급됩니다.',
                  ),
                  const SizedBox(height: 8),
                  const BullitText(
                    text: '1일 1회 참여 가능하며, 중복 참여는 불가합니다.',
                  ),
                  const SizedBox(height: 8),
                  const BullitText(
                    text: '부적절한 사진은 통보 없이 삭제될 수 있습니다.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 미션 참여하기 버튼 탭 시 등록 펫 수에 따라 화면 분기
  ///
  /// - 0마리 → PetEmptyScreen (펫 없음 안내)
  /// - 1마리 → CameraScreen (바로 카메라)
  /// - 2마리 이상 → PetSelectScreen (펫 선택)
  void _onMissionParticipate(BuildContext context) {
    // TODO: 실제 API 연동 후 등록된 펫 목록을 가져와 교체
    // 현재는 더미 데이터로 동작 (앱 전체가 더미 데이터 단계)
    final List<PetSelectCardData> registeredPets = _dummyPets;

    if (registeredPets.isEmpty) {
      // 0마리: 펫 없음 안내 화면
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PetEmptyScreen(
            onAddPetPressed: () {
              // TODO: 마이 펫 추가 화면으로 이동 (추후 구현)
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else if (registeredPets.length == 1) {
      // 1마리: 바로 카메라 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
    } else {
      // 2마리 이상: 펫 선택 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PetSelectScreen(pets: registeredPets),
        ),
      );
    }
  }

  /// 더미 펫 데이터 (실제 API 연동 전까지 사용)
  static final List<PetSelectCardData> _dummyPets = [
    const PetSelectCardData(
      name: '콩두리',
      breed: '웰시코기',
      ageText: '2살',
      genderText: '남아',
      isFavorite: true,
      imageProvider: NetworkImage(
        'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=150&h=150&fit=crop',
      ),
    ),
    const PetSelectCardData(
      name: '초코',
      breed: '푸들',
      ageText: '3살',
      genderText: '여아',
      imageProvider: NetworkImage(
        'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=150&h=150&fit=crop',
      ),
    ),
    const PetSelectCardData(
      name: '크림이',
      breed: '포메라니안',
      ageText: '1살',
      genderText: '남아',
      imageProvider: NetworkImage(
        'https://images.unsplash.com/photo-1596492784531-6e6eb5ea9993?w=150&h=150&fit=crop',
      ),
    ),
  ];
}
