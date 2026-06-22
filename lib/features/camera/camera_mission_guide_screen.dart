import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/widgets/popup_header.dart';
import '../../core/widgets/bullit_text.dart';
import 'camera_screen.dart';

class CameraMissionGuideScreen extends StatelessWidget {
  const CameraMissionGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double baselineX = MediaQuery.of(context).size.width / 2 - 187.5;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // var(--color/gray/20)
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

                        // A. 타이틀 배지 및 일러스트 그래픽 영역 (Figma absolute positioning 및 개별 레이어 재구성)
                        SizedBox(
                          height: 330,
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
                                left: baselineX + 111.42,
                                top: 172.64,
                                width: 159.12,
                                height: 142.947,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: -5.39 * (3.14159 / 180),
                                    child: Image.asset(
                                      'assets/images/banner/camera1.png',
                                      width: 147.587,
                                      height: 129.648,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // 2. 강아지 (Figma Node 327:12194)
                              Positioned(
                                left: baselineX + 79.13,
                                top: 222.59,
                                width: 55.353,
                                height: 69.323,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: -2.45 * (3.14159 / 180),
                                    child: Image.asset(
                                      'assets/images/banner/dog11.png',
                                      width: 52.534,
                                      height: 67.141,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // 3. 고양이 (Figma Node 327:12195)
                              Positioned(
                                left: baselineX + 237.32,
                                top: 197.69,
                                width: 69.796,
                                height: 70.324,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: -24.02 * (3.14159 / 180),
                                    child: Image.asset(
                                      'assets/images/banner/cat41.png',
                                      width: 52.534,
                                      height: 53.578,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // 4. 동전 5 (Figma Node 551:6819)
                              Positioned(
                                left: baselineX + 93.15,
                                top: 179.42,
                                width: 29.078,
                                height: 30.107,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: -30.5 * (3.14159 / 180),
                                    child: Image.asset(
                                      'assets/images/banner/coin51.png',
                                      width: 20.161,
                                      height: 23.066,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // 5. 동전 4 (Figma Node 551:6844)
                              Positioned(
                                left: baselineX + 223.36,
                                top: 273.34,
                                width: 48.274,
                                height: 50.653,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: 22.84 * (3.14159 / 180),
                                    child: Image.asset(
                                      'assets/images/banner/coin42.png',
                                      width: 35.536,
                                      height: 39.996,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              // 6. 꽃 8 (Figma Node 338:12544)
                              Positioned(
                                left: baselineX + 83.44,
                                top: 305.9,
                                width: 16.032,
                                height: 16.249,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: 28.87 * (3.14159 / 180),
                                    child: Image.asset(
                                      'assets/images/banner/flower8.png',
                                      width: 11.604,
                                      height: 12.157,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              // 7. 꽃 7 (Figma Node 338:12545)
                              Positioned(
                                left: baselineX + 65.65,
                                top: 298.19,
                                width: 16.351,
                                height: 17.39,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: -11.55 * (3.14159 / 180),
                                    child: Image.asset(
                                      'assets/images/banner/flower7.png',
                                      width: 13.63,
                                      height: 14.964,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              // 8. 꽃 6 (Figma Node 338:12546)
                              Positioned(
                                left: baselineX + 315.99,
                                top: 203.3,
                                width: 13.006,
                                height: 13.468,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: 20.94 * (3.14159 / 180),
                                    child: Image.asset(
                                      'assets/images/banner/flower6.png',
                                      width: 9.85,
                                      height: 10.652,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              // 9. 데코레이션 원형 1591 (Figma Node 338:12549)
                              Positioned(
                                left: baselineX + 311.42,
                                top: 287.63,
                                width: 2,
                                height: 2,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // 10. 데코레이션 원형 1592 (Figma Node 338:12550)
                              Positioned(
                                left: baselineX + 335.4,
                                top: 194.44,
                                width: 4,
                                height: 4,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // 11. 데코레이션 원형 1590 (Figma Node 484:26023)
                              Positioned(
                                left: baselineX + 66.45,
                                top: 183.24,
                                width: 3,
                                height: 3,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // 12. 그린 플러스 Union 1 (Figma Node 338:12559)
                              Positioned(
                                left: baselineX + 36.98,
                                top: 206.35,
                                width: 12,
                                height: 12,
                                child: SvgPicture.asset(
                                  'assets/images/banner/union_plus_1.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF79FFAE),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),

                              // 13. 그린 플러스 Union 2 (Figma Node 338:12560)
                              Positioned(
                                left: baselineX + 294.08,
                                top: 295.0,
                                width: 8.93,
                                height: 8.93,
                                child: SvgPicture.asset(
                                  'assets/images/banner/union_plus_2.svg',
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
                                top: 91.25,
                                child: Transform.rotate(
                                  angle: -4.6 * (3.14159 / 180),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                                    child: const Text(
                                      '리워드 받아요!',
                                      style: TextStyle(
                                        fontFamily: 'Gmarket Sans',
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.96,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // 15. 상단 배지 (마이 펫 촬영하고)
                              Positioned(
                                top: 34,
                                child: Transform.rotate(
                                  angle: 2.58 * (3.14159 / 180),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(9999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          offset: const Offset(2, 4),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      '마이 펫 촬영하고',
                                      style: TextStyle(
                                        fontFamily: 'Gmarket Sans',
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.96,
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
                                left: baselineX + 251.68,
                                top: 141.96,
                                width: 26.46,
                                height: 24.652,
                                child: Center(
                                  child: Transform.rotate(
                                    angle: 15.62 * (3.14159 / 180),
                                    child: Image.asset(
                                      'assets/images/banner/heart2.png',
                                      width: 22.042,
                                      height: 19.436,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                                  color: const Color(0xFFF4F6F8),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: const Text(
                                  '오늘의 수행 미션',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6C737F),
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
                                  color: Color(0xFF51565F),
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
                                        color: const Color(0xFFFF5F5F),
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
                                  color: Color(0xFF87909E),
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
                              // 카메라 촬영 화면으로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CameraScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF30343C), // Figma 검정/진회색 배경
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
              color: const Color(0xFFF4F6F8), // var(--color/gray/20)
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이벤트 유의사항',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF51565F),
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
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
