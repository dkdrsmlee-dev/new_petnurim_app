import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_routes.dart';
import '../../core/widgets/popup_header.dart';
import '../../core/widgets/bullit_text.dart';
import '../../core/widgets/pet_select_card.dart';
import '../../core/widgets/authed_file_image.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/widgets/edge_button_dialog.dart';
import '../../core/utils/toast_util.dart';
import 'domain/photo_event_models.dart';
import 'data/photo_event_repository.dart';
import '../member/data/pet_repository.dart';
import '../member/domain/pet_codes.dart';
import '../member/domain/pet_models.dart';
import 'camera_screen.dart';
import 'pet_select_screen.dart';
import '../../core/theme/app_colors.dart';

/// 대표펫(마이펫 목록의 `representYn = Y`) 1건을 조회한다.
/// 촬영 펫 목록 API에는 대표펫 정보가 없어 별도로 가져오며, 실패하면 null(배지 미표시).
Future<MyPetListItem?> _fetchRepresentPet(WidgetRef ref) async {
  try {
    final res = await ref.read(petRepositoryProvider).getMyPetsList(limit: 100);
    for (final pet in res.items) {
      if (YesNo.isYes(pet.representYn)) return pet;
    }
  } catch (_) {
    // 대표펫 표시는 부가 정보라 실패해도 촬영 플로우를 막지 않는다.
  }
  return null;
}

/// 성별 코드/값을 표시용 문자열로 변환
String _genderText(String? gender) {
  switch (gender?.trim().toUpperCase()) {
    case 'MALE':
    case 'M':
      return '남아';
    case 'FEMALE':
    case 'F':
      return '여아';
    default:
      return gender ?? '';
  }
}

/// guideContent 등 HTML 문자열을 평문으로 변환한다.
/// (기존 텍스트 스타일을 그대로 유지하기 위해 태그만 제거)
String? _htmlToPlainText(String? html) {
  if (html == null || html.trim().isEmpty) return null;
  final text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>|</div>|</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '') // 나머지 태그 제거
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\n{2,}'), '\n')
      .trim();
  return text.isEmpty ? null : text;
}

class CameraMissionGuideScreen extends ConsumerWidget {
  const CameraMissionGuideScreen({super.key, required this.eventMasterId});

  /// 사진(PHOTO) 이벤트 마스터 ID (홈 촬영 카드에서 templates.photo 로부터 전달)
  final String eventMasterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 사진 이벤트 상세(미션명·가이드·리워드·기간)로 하드코딩 대체 (없으면 폴백)
    final detailAsync = ref.watch(photoEventDetailProvider(eventMasterId));
    final detail = detailAsync.value;
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
                  // 그라데이션 동그라미 데코레이션 2 (Figma Ellipse 1593: 46,73.4 / 283×283)
                  // SVG에 담긴 feGaussianBlur(σ=42)를 flutter_svg가 지원하지 않아
                  // 선명한 원으로 렌더됐다. 원을 직접 그리고 같은 σ로 블러를 건다.
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 141.5,
                    top: 73.4,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 42, sigmaY: 42),
                      child: Container(
                        width: 283,
                        height: 283,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x4DABBCFF), // #ABBCFF 30%
                        ),
                      ),
                    ),
                  ),

                  // 본문 콘텐츠 리스트 (수직 플로우)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // A. 타이틀 배지 및 일러스트 그래픽 영역 (반응형 스케일링 적용)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double screenWidth = MediaQuery.of(
                              context,
                            ).size.width;
                            final double s =
                                screenWidth / 375; // 기준 해상도 375px 대비 스케일 비율
                            // 이 Stack 은 Padding(horizontal: 16) 안에 있어
                            // 좌표 원점이 화면 좌측이 아니라 16dp 지점이다.
                            // 화면 폭 기준으로 잡으면 일러스트가 통째로 16dp
                            // 오른쪽으로 밀리므로 Stack 자신의 중앙을 쓴다.
                            final double cx = constraints.maxWidth / 2;
                            return SizedBox(
                              height: 344 * s, // Figma: 아래 '미션 수행 시' 텍스트가 y=344
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
                                    left: cx - 187.5 * s + 111.42 * s,
                                    top: 172.64 * s,
                                    width: 159.12 * s,
                                    height: 142.947 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -5.39 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/camera1.png',
                                          width: 147.587 * s,
                                          height: 129.648 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 2. 강아지 (Figma Node 327:12194)
                                  Positioned(
                                    left: cx - 187.5 * s + 79.13 * s,
                                    top: 222.59 * s,
                                    width: 55.353 * s,
                                    height: 69.323 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -2.45 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/dog11.png',
                                          width: 52.534 * s,
                                          height: 67.141 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 3. 고양이 (Figma Node 327:12195)
                                  Positioned(
                                    left: cx - 187.5 * s + 237.32 * s,
                                    top: 197.69 * s,
                                    width: 69.796 * s,
                                    height: 70.324 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -24.02 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/cat41.png',
                                          width: 52.534 * s,
                                          height: 53.578 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 4. 동전 5 (Figma Node 551:6819)
                                  Positioned(
                                    left: cx - 187.5 * s + 93.15 * s,
                                    top: 179.42 * s,
                                    width: 29.078 * s,
                                    height: 30.107 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -30.5 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/coin51.png',
                                          width: 20.161 * s,
                                          height: 23.066 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 5. 동전 4 (Figma Node 551:6844)
                                  Positioned(
                                    left: cx - 187.5 * s + 223.36 * s,
                                    top: 273.34 * s,
                                    width: 48.274 * s,
                                    height: 50.653 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: 22.84 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/coin42.png',
                                          width: 35.536 * s,
                                          height: 39.996 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 6. 꽃 8 (Figma Node 338:12544)
                                  Positioned(
                                    left: cx - 187.5 * s + 83.44 * s,
                                    top: 305.9 * s,
                                    width: 16.032 * s,
                                    height: 16.249 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: 28.87 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/flower8.png',
                                          width: 11.604 * s,
                                          height: 12.157 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 7. 꽃 7 (Figma Node 338:12545)
                                  Positioned(
                                    left: cx - 187.5 * s + 65.65 * s,
                                    top: 298.19 * s,
                                    width: 16.351 * s,
                                    height: 17.39 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -11.55 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/flower7.png',
                                          width: 13.63 * s,
                                          height: 14.964 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 8. 꽃 6 (Figma Node 338:12546)
                                  Positioned(
                                    left: cx - 187.5 * s + 315.99 * s,
                                    top: 203.3 * s,
                                    width: 13.006 * s,
                                    height: 13.468 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: 20.94 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/flower6.png',
                                          width: 9.85 * s,
                                          height: 10.652 * s,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 9. 데코레이션 원형 1591 (Figma Node 338:12549)
                                  Positioned(
                                    left: cx - 187.5 * s + 311.42 * s,
                                    top: 287.63 * s,
                                    width: 2 * s,
                                    height: 2 * s,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),

                                  // 10. 데코레이션 원형 1592 (Figma Node 338:12550)
                                  Positioned(
                                    left: cx - 187.5 * s + 335.4 * s,
                                    top: 194.44 * s,
                                    width: 4 * s,
                                    height: 4 * s,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),

                                  // 11. 데코레이션 원형 1590 (Figma Node 484:26023)
                                  Positioned(
                                    left: cx - 187.5 * s + 66.45 * s,
                                    top: 183.24 * s,
                                    width: 3 * s,
                                    height: 3 * s,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),

                                  // 12. 그린 플러스 Union 1 (Figma Node 338:12559)
                                  Positioned(
                                    left: cx - 187.5 * s + 36.98 * s,
                                    top: 206.35 * s,
                                    width: 12.001 * s,
                                    height: 12.001 * s,
                                    child: SvgPicture.asset(
                                      'assets/images/banner/union_plus_1.svg',
                                      width: 12.001 * s,
                                      height: 12.001 * s,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF79FFAE),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),

                                  // 13. 그린 플러스 Union 2 (Figma Node 338:12560)
                                  Positioned(
                                    left: cx - 187.5 * s + 294.08 * s,
                                    top: 295 * s,
                                    width: 8.933 * s,
                                    height: 8.933 * s,
                                    child: SvgPicture.asset(
                                      'assets/images/banner/union_plus_2.svg',
                                      width: 8.933 * s,
                                      height: 8.933 * s,
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
                                    // 피그마 484:26018 wrapper top(91.25)은 '회전 후
                                    // bbox' 기준이고, 여기 top 은 '회전 전' 레이아웃
                                    // 상단이라 값이 다르다. bbox 중심(91.25+74.754/2)
                                    // 에서 알약 높이 절반을 뺀 값이 회전 전 상단.
                                    top: 100.21 * s,
                                    child: Transform.rotate(
                                      angle: -4.6 * (3.14159 / 180),
                                      child: _OuterHardShadow(
                                        child: _GradientStadiumBorder(
                                          topAlpha: 0.35,
                                          bottomAlpha: 0.18,
                                          child: Container(
                                            // 피그마는 알약 크기를 명시한다. 패딩+글자폭으로
                                            // 정하면 폰트(Gmarket Sans → Pretendard)가 달라
                                            // 폭이 어긋나므로 명시값을 그대로 쓴다.
                                            width: 225.693 * s,
                                            height: 56.844 * s,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF423F99,
                                              ).withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(9999),
                                            ),
                                            child: Text(
                                              '리워드 받아요!',
                                              style: TextStyle(
                                                // 피그마 스펙 32. Pretendard 가 Gmarket Sans 보다 1.13배
                                                // 좁아 알약 안 여백은 더 넓어지지만, 크기를 키우면 글자
                                                // 자체가 13% 커진다(실측 32 → 높이 35.1 = 피그마 35.3).
                                                fontSize: 32 * s,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: -0.96 * s,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 15. 상단 배지 (마이 펫 촬영하고)
                                  Positioned(
                                    // 피그마 484:26017 wrapper top(34) → 회전 전 상단
                                    top: 39.68 * s,
                                    child: Transform.rotate(
                                      angle: 2.58 * (3.14159 / 180),
                                      child: _OuterHardShadow(
                                        child: _GradientStadiumBorder(
                                          topAlpha: 0.70,
                                          bottomAlpha: 0.50,
                                          child: Container(
                                            // 피그마는 알약 크기를 명시한다. 패딩+글자폭으로
                                            // 정하면 폰트(Gmarket Sans → Pretendard)가 달라
                                            // 폭이 어긋나므로 명시값을 그대로 쓴다.
                                            width: 253.664 * s,
                                            height: 56.843 * s,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              // 피그마 레이어 속성은 흰색 20% 반투명이지만,
                                              // 실제 피그마 렌더에서는 아래 리워드 배지가
                                              // 전혀 비치지 않는다(x=741·859·900·940 어디서도
                                              // 채움이 균일). 앱에서 반투명으로 두면 두 배지가
                                              // 살짝 겹치는 구간에서 리워드가 비쳐 보이므로,
                                              // 렌더 결과와 같은 합성 단색을 쓴다.
                                              color: const Color(0xFF7C83EE),
                                              borderRadius:
                                                  BorderRadius.circular(9999),
                                            ),
                                            child: Text(
                                              '마이 펫 촬영하고',
                                              style: TextStyle(
                                                // 피그마 스펙 32. Pretendard 가 Gmarket Sans 보다 1.13배
                                                // 좁아 알약 안 여백은 더 넓어지지만, 크기를 키우면 글자
                                                // 자체가 13% 커진다(실측 32 → 높이 35.1 = 피그마 35.3).
                                                fontSize: 32 * s,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: -0.96 * s,
                                              ),
                                            ),
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
                                    left: cx - 187.5 * s + 251.68 * s,
                                    top: 141.96 * s,
                                    width: 26.46 * s,
                                    height: 24.652 * s,
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: 15.62 * (3.14159 / 180),
                                        child: Image.asset(
                                          'assets/images/banner/heart2.png',
                                          width: 22.042 * s,
                                          height: 19.436 * s,
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
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF3F7FF),
                              letterSpacing: -0.66,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(text: '미션 수행 시 매일 '),
                              TextSpan(
                                text: '${detail?.rewardValue ?? 100}PR ',
                                style: const TextStyle(
                                  color: Color(0xFFFF8FE7),
                                ),
                              ),
                              const TextSpan(text: '지급!'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail?.eventPeriod ?? '2026.4.1~4.30',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF3F7FF),
                            letterSpacing: -0.66,
                            height: 1.4,
                          ),
                        ),

                        // 텍스트 프레임 344~392, 미션 박스 416 → 간격 24 (Figma 492:26040)
                        const SizedBox(height: 24),

                        // D. 오늘의 수행 미션 카드 (Mission Box)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
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
                              // 타이틀: 이벤트 title (예: "송곳니찍기")
                              Text(
                                (detail?.title.isNotEmpty ?? false)
                                    ? detail!.title
                                    : '송곳니를 촬영해 주세요!',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: -0.66,
                                ),
                              ),
                              const SizedBox(height: 18),  // Figma 18

                              // 이미지 예시 카드 영역
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    // 표시 창(가로 전체 × 92)에 직접 맞춘다.
                                    //
                                    // 이전에는 Figma의 img 노드(551:6866)가 358×358인
                                    // 것을 그대로 옮겨 358 정사각형에 cover 로 채웠는데,
                                    // 백엔드가 내려주는 이미지는 이미 이 창 크기(311×92)로
                                    // 잘라 등록된 최종본이라 짧은 변을 358에 맞추느라
                                    // 3.89배 확대되고 가로가 30%만 남았다.
                                    // Figma가 358인 것은 디자이너가 정사각 사진을 놓고
                                    // 이 창으로 크롭한 결과일 뿐이다.
                                    //
                                    // alignment 0.235 = 정사각 원본이 등록될 때 Figma가
                                    // 보여주던 띠(이미지 높이의 43.5~69.2%)를 재현하는 값.
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 92,
                                      // 상세 로딩 중엔 셔머(에셋 폴백이 잠깐 보이지
                                      // 않도록) → 로드 후 이미지(있으면)/에셋(없으면).
                                      child: detailAsync.isLoading
                                          ? const ShimmerBox()
                                          : (detail?.detailImageFileId != null
                                                ? Image(
                                                    image: AuthedFileImageX.of(
                                                      ref,
                                                      detail!
                                                          .detailImageFileId!,
                                                      variant: 'medium',
                                                    ),
                                                    fit: BoxFit.cover,
                                                    alignment: const Alignment(
                                                      0,
                                                      0.235,
                                                    ),
                                                    // 이미지 다운로드 중 셔머 →
                                                    // 로드 완료 시 교체.
                                                    frameBuilder:
                                                        shimmerImageFrameBuilder,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => Image.asset(
                                                          'assets/images/banner/fangs_guide.png',
                                                          fit: BoxFit.cover,
                                                          alignment:
                                                              const Alignment(
                                                                0,
                                                                0.235,
                                                              ),
                                                        ),
                                                  )
                                                : Image.asset(
                                                    'assets/images/banner/fangs_guide.png',
                                                    fit: BoxFit.cover,
                                                    alignment: const Alignment(
                                                      0,
                                                      0.235,
                                                    ),
                                                  )),
                                    ),
                                  ),
                                  // 촬영 예시 빨간 뱃지
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
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
                              const SizedBox(height: 18),  // Figma 18

                              // 설명 텍스트 (guideContent HTML → 평문, 기존 디자인 유지)
                              Text(
                                _htmlToPlainText(detail?.guideContent) ??
                                    '마이 펫의 송곳니 부분이 잘 보이도록\n선명하게 촬영해 주세요.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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

                        const SizedBox(
                          height: 20,
                        ), // 미션 카드 ~ 참여 버튼 간격 (Figma: 박스 하단 707 → 버튼 727 = 20)
                        // E. 미션 참여하기 버튼
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0x4D47287C,
                                ), // rgba(71, 40, 124, 0.3)
                                offset: const Offset(0, 4),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _onMissionParticipate(context, ref);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.textStrong, // Figma 검정/진회색 배경
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
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
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 32,
                bottom: 50,
              ),
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
                  BullitText(
                    text: '미션 수행 시 ${detail?.rewardValue ?? 100}PR이 즉시 지급됩니다.',
                  ),
                  const SizedBox(height: 8),
                  const BullitText(text: '1일 1회 참여 가능하며, 중복 참여는 불가합니다.'),
                  const SizedBox(height: 8),
                  const BullitText(text: '부적절한 사진은 통보 없이 삭제될 수 있습니다.'),
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
  /// - 0마리 → 마이펫 등록 안내 다이얼로그
  /// - 1마리 → CameraScreen (바로 카메라)
  /// - 2마리 이상 → PetSelectScreen (펫 선택)
  Future<void> _onMissionParticipate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // 촬영 이벤트 전용 펫 목록(/pets)을 조회해 화면을 분기한다.
    List<PhotoEventPet> pets;
    try {
      pets = await ref
          .read(photoEventRepositoryProvider)
          .getPets(eventMasterId);
    } catch (_) {
      if (context.mounted) {
        ToastUtil.show(context, '펫 정보를 불러오지 못했습니다. 다시 시도해 주세요.');
      }
      return;
    }

    // 촬영 펫 목록 API(/pets)는 대표펫 여부를 주지 않으므로 마이펫 목록에서 가져온다.
    // (조회 실패해도 촬영 플로우는 그대로 진행 — 대표펫 배지만 표시되지 않음)
    final representPet = await _fetchRepresentPet(ref);
    if (!context.mounted) return;

    // 참여 결과에 리워드가 없을 때 사용할 예비 리워드 값(상세 API의 리워드)
    final rewardHint = ref
        .read(photoEventDetailProvider(eventMasterId))
        .value
        ?.rewardValue;

    bool isRepresent(PhotoEventPet pet) {
      if (representPet == null) return false;
      // 두 API의 펫 식별자가 동일하다는 보장이 없어 ID 우선 매칭 후 이름으로 폴백한다.
      final idMatched = pets.any((p) => p.petId == representPet.myPetId);
      return idMatched
          ? pet.petId == representPet.myPetId
          : pet.petName == representPet.petName;
    }

    // PhotoEventPet → PetSelectCardData 매핑
    final List<PetSelectCardData> registeredPets = pets
        .map(
          (pet) => PetSelectCardData(
            petId: pet.petId,
            name: pet.petName,
            breed: (pet.breedName != null && pet.breedName!.isNotEmpty)
                ? pet.breedName!
                : '믹스',
            // age 필드는 백엔드에서 이미 "3살" 형태로 내려오므로 그대로 사용
            ageText: pet.age ?? '',
            genderText: _genderText(pet.gender),
            isFavorite: isRepresent(pet),
            imageProvider: pet.thumbnailFileId != null
                ? AuthedFileImageX.of(
                    ref,
                    pet.thumbnailFileId!,
                    variant: 'thumb',
                  )
                : null,
          ),
        )
        .toList();

    if (registeredPets.isEmpty) {
      // 0마리: 마이펫 등록 안내 다이얼로그 (Figma USR-EVT-016)
      final router = GoRouter.of(context);
      showDialog(
        context: context,
        builder: (_) => EdgeButtonDialog(
          title: '아이 등록이 필요해요.',
          content: '아이 등록 후 리워드 이벤트에\n참여할 수 있어요.',
          cancelText: '닫기',
          confirmText: '마이펫 등록',
          onConfirm: () {
            // 카메라 미션 플로우를 닫고 마이펫 추가 화면으로 이동
            Navigator.of(context).popUntil((route) => route.isFirst);
            router.push(AppRoutes.myPetAdd);
          },
        ),
      );
    } else if (registeredPets.length == 1) {
      // 1마리: 바로 카메라 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraScreen(
            eventMasterId: eventMasterId,
            petId: registeredPets.first.petId,
            rewardValueHint: rewardHint,
          ),
        ),
      );
    } else {
      // 2마리 이상: 펫 선택 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PetSelectScreen(
            pets: registeredPets,
            eventMasterId: eventMasterId,
            rewardValueHint: rewardHint,
          ),
        ),
      );
    }
  }
}

/// 피그마 배지에는 CSS 로 내보내지지 않는 1px 흰색 그라데이션 스트로크가 있다
/// (Figma 코드 생성이 그라데이션 스트로크를 누락한다). 렌더 픽셀에서 역산한
/// 불투명도를 위→아래 선형 그라데이션으로 재현한다.
class _GradientStadiumBorder extends StatelessWidget {
  const _GradientStadiumBorder({
    required this.child,
    required this.topAlpha,
    required this.bottomAlpha,
  });

  final Widget child;
  final double topAlpha;
  final double bottomAlpha;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _GradientStadiumBorderPainter(topAlpha, bottomAlpha),
      child: child,
    );
  }
}

class _GradientStadiumBorderPainter extends CustomPainter {
  const _GradientStadiumBorderPainter(this.topAlpha, this.bottomAlpha);

  final double topAlpha;
  final double bottomAlpha;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // 선 두께 1 의 절반만큼 안쪽으로 들여 그려야 선이 잘리지 않는다.
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: topAlpha),
            Colors.white.withValues(alpha: bottomAlpha),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GradientStadiumBorderPainter old) =>
      old.topAlpha != topAlpha || old.bottomAlpha != bottomAlpha;
}

/// 피그마의 drop shadow 는 알약 안쪽으로 비치지 않는다. 마이펫 배지 채움이
/// 흰색 20% 반투명인데도 피그마 렌더의 채움값이 '그림자 없는 합성값'과
/// 일치하는 것으로 확인했다. Flutter BoxShadow 는 박스 아래에 그대로 깔려
/// 반투명 배지를 통과하므로, 배지 모양을 도려낸 바깥 그림자만 그린다.
class _OuterHardShadow extends StatelessWidget {
  const _OuterHardShadow({required this.child});

  /// 피그마 484:26017·484:26018 의 shadow: 2px 4px 0px rgba(0,0,0,0.2)
  static const Offset _offset = Offset(2, 4);
  static const Color _color = Color(0x33000000);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _OuterHardShadowPainter(), child: child);
  }
}

class _OuterHardShadowPainter extends CustomPainter {
  const _OuterHardShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height / 2),
    );
    canvas.saveLayer(
      rect.inflate(_OuterHardShadow._offset.distance + 4),
      Paint(),
    );
    canvas.drawRRect(
      rrect.shift(_OuterHardShadow._offset),
      Paint()..color = _OuterHardShadow._color,
    );
    canvas.drawRRect(rrect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OuterHardShadowPainter old) => false;
}
