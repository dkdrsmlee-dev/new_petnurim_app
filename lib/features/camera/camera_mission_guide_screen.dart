import 'package:flutter/material.dart';
import '../../core/widgets/popup_header.dart';
import '../../core/widgets/bullit_text.dart';
import 'camera_screen.dart';

class CameraMissionGuideScreen extends StatelessWidget {
  const CameraMissionGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                children: [
                  // 그라데이션 동그라미 데코레이션 1
                  Positioned(
                    left: -130,
                    top: 267,
                    child: Container(
                      width: 650,
                      height: 360,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // 그라데이션 동그라미 데코레이션 2
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 141.5,
                    top: 73,
                    child: Container(
                      width: 283,
                      height: 283,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),

                  // 본문 콘텐츠 리스트 (수직 플로우)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 34), // Figma top-[34px]

                        // A. 상단 타이틀 배지
                        Transform.rotate(
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
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.66,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Transform.rotate(
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
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.66,
                              ),
                            ),
                          ),
                        ),

                        // B. 일러스트 그래픽 영역 (Figma Node 484:26020 - 배지 2 하단 Y:148.09에서 텍스트 Y:344까지 197.4px 영역 확보)
                        SizedBox(
                          width: 263.15,
                          height: 197.4,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 0,
                                top: -9.56, // 피그마 Y:138.53 -> 배지2 하단 Y:148.09 대비 오프셋
                                width: 263.15,
                                height: 213.2,
                                child: Image.asset(
                                  'assets/images/banner/illust_banner.png',
                                  fit: BoxFit.contain,
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
                                      child: Image.asset(
                                        'assets/images/banner/fangs_guide.png',
                                        fit: BoxFit.cover,
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
