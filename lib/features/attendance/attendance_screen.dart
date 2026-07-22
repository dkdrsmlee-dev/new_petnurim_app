import 'package:flutter/material.dart';
import '../../core/widgets/popup_header.dart';
import '../../core/widgets/calendar_grid.dart';
import '../../core/widgets/calendar_stamp.dart';
import '../../core/widgets/bullit_text.dart';
import '../../core/widgets/edge_button_dialog.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/reward_milestone_stamp.dart';
import '../../core/theme/app_colors.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Figma 이미지 URL 상수들
  static const String imgCheckTitle = "assets/images/banner/check_title.png";
  static const String imgCoin11 = "assets/images/banner/coin11.png";
  static const String imgCoin51 = "assets/images/banner/coin51.png";
  static const String imgCoin41 = "assets/images/banner/coin41.png";
  static const String imgCloud = "assets/images/banner/cloud.svg";
  static const String imgStar8 = "assets/images/banner/star8.svg";
  static const String imgStar11 = "assets/images/banner/star11.svg";
  static const String imgStar12 = "assets/images/banner/star12.svg";
  static const String imgStar13 = "assets/images/banner/star13.svg";
  static const String imgStar16 = "assets/images/banner/star16.svg";
  static const String imgStar9 = "assets/images/banner/star9.svg";
  static const String imgStamp1 = "assets/images/banner/stamp1.png";
  static const String imgAo1 = "assets/images/banner/ao1.png";
  static const String imgDlf1 = "assets/images/banner/dlf1.png";

  // 예시 데이터: 이번 달 출석 일수 및 출석일 목록
  final DateTime _today = DateTime(2026, 5, 14); // 스크린샷 기준 5월 14일
  final List<int> _attendedDays = [3, 4, 5, 11, 12, 13, 14];
  
  // 리워드 마일스톤 예시 데이터
  final List<Map<String, dynamic>> _milestones = [
    {'title': '7일 출석', 'points': 100, 'isCompleted': true},
    {'title': '14일 연속 출석', 'points': 200, 'isCompleted': false},
    {'title': '21일 연속 출석', 'points': 300, 'isCompleted': false},
    {'title': '28일 연속 출석', 'points': 400, 'isCompleted': false},
    {'title': '30일 연속 출석', 'points': 500, 'isCompleted': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PopupHeader(
        title: '출석 체크',
        showBackButton: false, // 스크린샷 요구사항: 뒤로가기 버튼 숨김
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 배너 영역
            _buildBannerSection(),
            
            const SizedBox(height: 32),
            
            // 2. 달력 영역
            _buildCalendarSection(),
            
            const SizedBox(height: 32),
            
            // 3. 오늘 출석하기 버튼
            _buildBottomButton(),
            
            const SizedBox(height: 48),
            
            // 4. 친구에게 소문내기 섹션
            _buildShareSection(),
            
            // 5. 이벤트 유의사항 섹션
            _buildNoticeSection(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      width: double.infinity,
      height: 558, // Figma 배너 영역 전체 높이
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF71C4FF), Color(0xFF71BAFF)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          SizedBox(
            width: 375, // Figma 기준 너비
              height: 558,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. 구름 및 벡터 배경 (SVG)
                  Positioned(
                    left: -56.29,
                    top: 167.43,
                    width: 448,
                    height: 266.024,
                    child: SvgPicture.asset(imgCloud, fit: BoxFit.cover),
                  ),



                  // 2. 별 장식들 (SVG) - React 코드 기반 완벽 동기화
                  _buildTransformedImage(imgStar11, isSvg: true, left: 207.82, top: 19.7, boundingWidth: 17.745, boundingHeight: 17.745, imageWidth: 13.584, imageHeight: 13.584, angle: -22.48),
                  _buildTransformedImage(imgStar12, isSvg: true, left: 216.69, top: 27.85, boundingWidth: 19.202, boundingHeight: 19.202, imageWidth: 16.786, imageHeight: 16.786, angle: 8.99),
                  _buildTransformedImage(imgStar13, isSvg: true, left: 53.07, top: 173.55, boundingWidth: 20.131, boundingHeight: 20.131, imageWidth: 14.25, imageHeight: 14.25, angle: 42.35),
                  _buildTransformedImage(imgStar8, isSvg: true, left: 298.29, top: 202, boundingWidth: 31.297, boundingHeight: 31.297, imageWidth: 24.797, imageHeight: 24.797, angle: 18.18),
                  _buildTransformedImage(imgStar9, isSvg: true, left: 322.44, top: 203.35, boundingWidth: 14.297, boundingHeight: 14.297, imageWidth: 12.7, imageHeight: 12.7, angle: 0),
                  _buildTransformedImage(imgStar16, isSvg: true, left: 45.09, top: 422.5, boundingWidth: 13.866, boundingHeight: 13.866, imageWidth: 10.783, imageHeight: 10.783, angle: 110.41),
                  _buildTransformedImage(imgStar13, isSvg: true, left: 52.49, top: 431, boundingWidth: 20.131, boundingHeight: 20.131, imageWidth: 14.25, imageHeight: 14.25, angle: 42.35),
                  _buildTransformedImage(imgStar12, isSvg: true, left: 299.4, top: 510.4, boundingWidth: 19.202, boundingHeight: 19.202, imageWidth: 16.786, imageHeight: 16.786, angle: 8.99),

                  // 3. 코인 장식들 (PNG)
                  _buildTransformedImage(imgCoin51, isSvg: false, left: 30.22, top: 20.7, boundingWidth: 34.232, boundingHeight: 36.596, imageWidth: 22.671, imageHeight: 29.161, angle: 30.07),
                  _buildTransformedImage(imgCoin41, isSvg: false, left: 308.52, top: 57.3, boundingWidth: 39.05, boundingHeight: 39.318, imageWidth: 27.532, imageHeight: 28.668, angle: 35.4),
                  _buildTransformedImage(imgCoin11, isSvg: false, left: 67.97, top: 180.84, boundingWidth: 35.621, boundingHeight: 35.621, imageWidth: 27.02, imageHeight: 27.02, angle: -23.78),

                  // 4. 서브 헤드라인 (가장 아래에 깔려야 하므로 일찍 선언)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 193 - 11.2, // Text center is 193 (translate-y-1/2 of 22.4)
                    child: const Text(
                      '찍을수록 쏟아지는 리워드!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.66,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // 5. 기간 뱃지 (도장보다 밑에 깔려야 함)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 217,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.textStrong,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Text(
                          '2026.4.1~4.30',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.66,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 6. 큰 보라색 도장 장식 (stamp 1) - 뱃지 위로 올라오도록 뱃지 다음 순서에 선언!
                  _buildTransformedImage(imgStamp1, isSvg: false, left: 235.49, top: 183.15, boundingWidth: 64.542, boundingHeight: 76.106, imageWidth: 51.677, imageHeight: 66.742, angle: 12.12),

                  // 7. 메인 3D 타이틀 ("출석체크")
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 65.88,
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 260,
                        height: 107,
                        child: Image.asset(imgCheckTitle, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                  // 8. 매일매일 글자 장식 (PNG) - 타이틀 위로 올라오도록 타이틀 다음에 선언!
                  _buildTransformedImage(imgAo1, isSvg: false, left: 111.58, top: 36, boundingWidth: 42, boundingHeight: 42, imageWidth: 42, imageHeight: 42, angle: 0),
                  _buildTransformedImage(imgDlf1, isSvg: false, left: 148.02, top: 40, boundingWidth: 42, boundingHeight: 42, imageWidth: 42, imageHeight: 42, angle: 0),
                  _buildTransformedImage(imgAo1, isSvg: false, left: 185.02, top: 45.04, boundingWidth: 42, boundingHeight: 42, imageWidth: 42, imageHeight: 42, angle: 0),
                  _buildTransformedImage(imgDlf1, isSvg: false, left: 221.42, top: 49, boundingWidth: 42, boundingHeight: 42, imageWidth: 42, imageHeight: 42, angle: 0),

                  // 9. 보상 마일스톤
                  Positioned(
                    top: 285,
                    left: 0,
                    right: 0,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: MilestoneLinePainter(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: _milestones.map((milestone) {
                              return RewardMilestoneStamp(
                                title: milestone['title'],
                                points: milestone['points'],
                                isCompleted: milestone['isCompleted'],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 헬퍼 메서드: 각도 회전과 절대 좌표 배치를 위한 위젯 생성기
  Widget _buildTransformedImage(String url,
      {required bool isSvg,
      required double left,
      required double top,
      required double boundingWidth,
      required double boundingHeight,
      required double imageWidth,
      required double imageHeight,
      required double angle}) {
    final isLocalAsset = url.startsWith('assets/');
    return Positioned(
      left: left,
      top: top,
      width: boundingWidth,
      height: boundingHeight,
      child: Center(
        child: Transform.rotate(
          angle: angle * (3.1415926535897932 / 180),
          child: SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: isSvg
                ? (isLocalAsset
                    ? SvgPicture.asset(url, fit: BoxFit.contain)
                    : SvgPicture.network(url, fit: BoxFit.contain, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))
                : (isLocalAsset
                    ? Image.asset(url, fit: BoxFit.contain)
                    : Image.network(url, fit: BoxFit.contain)),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 달력 타이틀 및 출석 현황
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_today.month}월',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textStrong,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  children: [
                    const Text(
                      '이번 달 출석 ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${_attendedDays.length}일',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 달력 그리드
          CalendarGrid(
            year: _today.year,
            month: _today.month,
            dayBuilder: (context, date, isOutsideMonth) {
              final isAttended = !isOutsideMonth && _attendedDays.contains(date.day);
              final isToday = !isOutsideMonth && date.day == _today.day;
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 날짜 텍스트 (출석 완료 시에는 도장으로 덮어지므로 숨김)
                  if (!isAttended)
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isOutsideMonth ? FontWeight.w500 : FontWeight.w600,
                        color: isOutsideMonth
                            ? AppColors.border
                            : AppColors.textTertiary,
                      ),
                    ),
                  // 스탬프 오버레이
                  if (!isOutsideMonth && (isAttended || isToday))
                    CalendarStamp(
                      isAttended: isAttended,
                      showToday: isToday,
                      showReward: isAttended && isToday,
                      rewardPoint: 100,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4D47287C), // rgba(71,40,124,0.3)
              offset: Offset(0, 4),
              blurRadius: 3,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => EdgeButtonDialog(
                  title: '일일 출석체크가 완료되었어요!',
                  confirmText: '확인',
                  onConfirm: () {
                    showDialog(
                      context: context,
                      builder: (context) => EdgeButtonDialog(
                        title: '출석체크 완료!\n리워드 100PR이 지급되었어요!',
                        confirmText: '확인',
                        onConfirm: () {},
                        topWidget: SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 1,
                                bottom: 1,
                                width: 56,
                                height: 56,
                                child: Image.asset(
                                  'assets/images/ic_coin.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                width: 12,
                                height: 12,
                                child: SvgPicture.asset(
                                  'assets/images/ic_star_large.svg',
                                ),
                              ),
                              Positioned(
                                left: 0,
                                bottom: 0,
                                width: 9,
                                height: 9,
                                child: SvgPicture.asset(
                                  'assets/images/ic_star_small.svg',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  topWidget: Image.asset(
                    'assets/images/ic_pet_foot.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
            child: const Center(
              child: Text(
                '오늘 출석하기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.54,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareSection() {
    return Container(
      width: double.infinity,
      height: 228,
      color: const Color(0xFF383E62), // 피그마 지정 배경색
      child: Center(
        child: SizedBox(
          width: 375,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // 배경 그라데이션 타원
              Positioned(
                top: 197.5 - 86.0,
                left: 188.0 - 206.7,
                child: Container(
                  width: 206.7 * 2,
                  height: 86.0 * 2,
                  decoration: const BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.elliptical(206.7, 86.0)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF7079AA),
                        Color(0xFF383E62),
                      ],
                      stops: [0.0, 0.69],
                    ),
                  ),
                ),
              ),

              // 공유 버튼 묶음 박스 (Drop shadow 추가)
              Positioned(
                top: 80.5,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33101828), // rgba(16, 24, 40, 0.2)
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildShareIconItem(
                        child: _buildKakaoIcon(),
                        label: '카카오',
                      ),
                      const SizedBox(width: 57),
                      _buildShareIconItem(
                        child: _buildInstaIcon(),
                        label: '인스타',
                      ),
                      const SizedBox(width: 57),
                      _buildShareIconItem(
                        child: _buildLinkIcon(),
                        label: '링크복사',
                      ),
                    ],
                  ),
                ),
              ),

              // 왼쪽 떠있는 강아지 말풍선
              Positioned(
                left: 56.6,
                top: 18.8,
                child: SizedBox(
                  width: 26.7,
                  height: 26.7,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: SvgPicture.asset('assets/images/banner/ellipse1587.svg'),
                      ),
                      Positioned(
                        left: 60.0 - 56.6,
                        top: 24.3 - 18.8,
                        child: SizedBox(
                          width: 20,
                          height: 13.7,
                          child: Image.asset('assets/images/banner/dog-head-1.png'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 오른쪽 떠있는 고양이 말풍선
              Positioned(
                left: 308.6,
                top: 180.6,
                child: SizedBox(
                  width: 26.7,
                  height: 26.7,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: SvgPicture.asset('assets/images/banner/ellipse1587_purple.svg'),
                      ),
                      Positioned(
                        left: 314.0 - 308.6,
                        top: 185.9 - 180.6,
                        child: SizedBox(
                          width: 16,
                          height: 14.1,
                          child: Image.asset('assets/images/banner/cat-head-1.png'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 배경 반짝이 별 (Sparkle 1 - Dark Blue)
              Positioned(
                left: 299,
                top: 33,
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: SvgPicture.asset('assets/images/banner/sparkle_1.svg'),
                ),
              ),
              // 배경 반짝이 별 (Sparkle 2 - White with stroke)
              Positioned(
                left: 306,
                top: 39,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: SvgPicture.asset('assets/images/banner/sparkle_2.svg'),
                ),
              ),
              // 배경 반짝이 별 (Sparkle 3 - White with stroke)
              Positioned(
                left: 62,
                top: 55,
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: SvgPicture.asset('assets/images/banner/sparkle_3.svg'),
                ),
              ),
              // 배경 반짝이 별 (Sparkle 4 - White transparent)
              Positioned(
                left: 128,
                top: 196,
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: SvgPicture.asset('assets/images/banner/sparkle_4.svg'),
                ),
              ),

              // 타이틀 (친구에게 소문내기) - absolute positioning
              Positioned(
                top: 24,
                child: SizedBox(
                  width: 205,
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '친구에게',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Gmarket Sans',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.66,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 5,
                              top: 5,
                              child: Transform.rotate(
                                angle: -13.2376 * 3.1415926535 / 180,
                                alignment: Alignment.topLeft,
                                child: SizedBox(
                                  width: 40,
                                  height: 40.39,
                                  child: Image.asset('assets/images/banner/noti-1.png'),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 35,
                              top: 7,
                              child: _buildMegaphoneVectors(),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '소문내기',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Gmarket Sans',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: -0.66,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareIconItem({required Widget child, required String label}) {
    return SizedBox(
      width: 47,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              height: 1.4,
              letterSpacing: -0.66,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMegaphoneVectors() {
    const String vectorsSvg = '''
<svg width="12" height="18" viewBox="200 31 12 18" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M201.042 36.8033L205.701 32.1445" stroke="#F7FF1A" stroke-width="2" stroke-linecap="round"/>
  <path d="M203.372 41.1025L210.396 39.2207" stroke="#F7FF1A" stroke-width="2" stroke-linecap="round"/>
  <path d="M203.754 45.8174L210.396 47.5971" stroke="#F7FF1A" stroke-width="2" stroke-linecap="round"/>
</svg>
''';
    return SvgPicture.string(vectorsSvg);
  }

  Widget _buildKakaoIcon() {
    const String kakaoSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 3c-5.799 0-10.5 3.664-10.5 8.183 0 2.936 1.956 5.513 4.966 6.946l-1.042 3.86c-.057.208.188.369.36.242l4.475-2.955c.57.065 1.155.1 1.741.1 5.799 0 10.5-3.664 10.5-8.183S17.799 3 12 3z"/>
</svg>
''';

    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0xFFFAE524),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.string(
          kakaoSvg,
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildInstaIcon() {
    const String instaSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.88z"/>
</svg>
''';

    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/banner/insta_bg.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: SvgPicture.string(
              instaSvg,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkIcon() {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: AppColors.textMuted,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/images/banner/link_icon.svg',
          width: 14,
          height: 14,
        ),
      ),
    );
  }

  Widget _buildNoticeSection() {
    return Container(
      width: double.infinity,
      color: AppColors.bgGray, // 회색 배경
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '이벤트 유의사항',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              letterSpacing: -0.66,
            ),
          ),
          SizedBox(height: 12),
          BullitText(text: '미션 수행 시 100PR이 즉시 지급됩니다.'),
          SizedBox(height: 6),
          BullitText(text: '1일 1회 참여 가능하며, 중복 참여는 불가합니다.'),
          SizedBox(height: 6),
          BullitText(text: '부적절한 사진은 통보 없이 삭제될 수 있습니다.'),
        ],
      ),
    );
  }
}

class MilestoneLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 스탬프 너비: 90, 가로 간격: 20
    // 첫째 줄 너비 (3개): 90 * 3 + 20 * 2 = 310
    // 둘째 줄 너비 (2개): 90 * 2 + 20 = 200
    double row1StartX = (size.width - 310) / 2;
    double row2StartX = (size.width - 200) / 2;

    double y1 = 45.0; // 첫째 줄 스탬프 중심 Y좌표
    double y2 = 90.0 + 36.0 + 45.0; // 둘째 줄 스탬프 중심 Y좌표 (171.0)

    // 스탬프 중심 X좌표 계산
    Offset p1 = Offset(row1StartX + 45, y1); // 1번째 (7일)
    Offset p3 = Offset(row1StartX + 90 * 2 + 20 * 2 + 45, y1); // 3번째 (21일)
    Offset p4 = Offset(row2StartX + 45, y2); // 4번째 (28일)

    final paint = Paint()
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gradient = const LinearGradient(
      colors: [Color(0xFF86CAFF), Color(0xFF7CC8FF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    paint.shader = gradient.createShader(Rect.fromLTWH(0, y1, size.width, y2 - y1));

    final path = Path();
    path.moveTo(p1.dx, p1.dy);
    
    // 피그마 기준, 오른쪽 반원 커브는 세 번째 스탬프 중심(p3.dx)보다 약간 앞에서 시작해야
    // 우측 화면 여백(약 27.5px)이 확보되고 완벽한 반원(반지름 63)이 그려집니다.
    double arcStartX = p3.dx - 13.0; // 297.5 - 13 = 284.5

    path.lineTo(arcStartX, p3.dy);
    
    // 오른쪽 아래로 향하는 부드러운 반원 커브 곡선 (반지름 63)
    path.arcToPoint(
      Offset(arcStartX, y2), 
      radius: const Radius.circular(63),
      clockwise: true,
    );

    // 둘째 줄의 첫 번째 스탬프로 직선 연결 (자연스럽게 5번째 스탬프를 관통)
    path.lineTo(p4.dx, p4.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
