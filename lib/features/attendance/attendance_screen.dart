import 'package:flutter/material.dart';
import '../../core/widgets/popup_header.dart';
import '../../core/widgets/calendar_grid.dart';
import '../../core/widgets/calendar_stamp.dart';
import '../../core/widgets/bullit_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/reward_milestone_stamp.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Figma 이미지 URL 상수들
  static const String imgCheckTitle = "https://www.figma.com/api/mcp/asset/8854d0c7-a7ff-4093-9463-50d8ab0acd36";
  static const String imgCoin11 = "https://www.figma.com/api/mcp/asset/36bd6bef-6fbf-4fe6-8e8c-a298e57f7293";
  static const String imgCoin51 = "https://www.figma.com/api/mcp/asset/465d64c4-e296-4b4a-bd4c-332f86eef402";
  static const String imgCoin41 = "https://www.figma.com/api/mcp/asset/415c9fa1-a4dd-4486-a821-c449ffa56086";
  static const String imgCloud = "https://www.figma.com/api/mcp/asset/e967e12e-949e-4e8a-ba8a-d2a8f31aa603";
  static const String imgStar8 = "assets/images/banner/star8.svg";
  static const String imgStar11 = "assets/images/banner/star11.svg";
  static const String imgStar12 = "assets/images/banner/star12.svg";
  static const String imgStar13 = "assets/images/banner/star13.svg";
  static const String imgStar16 = "assets/images/banner/star16.svg";
  static const String imgStar9 = "assets/images/banner/star9.svg";
  static const String imgStamp1 = "https://www.figma.com/api/mcp/asset/d0a836fb-e9fa-4a88-97a1-a9f59bdeafec";
  static const String imgVector8 = "https://www.figma.com/api/mcp/asset/3fc7ca95-eb58-44ce-8d17-fbaba4f0bcd2";
  static const String imgAo1 = "https://www.figma.com/api/mcp/asset/7a48a4ae-4d08-48e5-9856-5032a1ce2104";
  static const String imgDlf1 = "https://www.figma.com/api/mcp/asset/e0f995db-a226-42be-9641-bf2aa1ca47de";

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
            
            const SizedBox(height: 32),
            
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
      height: 550, // Figma 배너 영역 전체 높이
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF71C4FF), Color(0xFF71BAFF)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 구름 및 벡터 배경 (SVG)
          Positioned(
            left: -56.29,
            top: 167.43,
            width: 448,
            height: 266,
            child: SvgPicture.network(imgCloud, fit: BoxFit.cover),
          ),

          // 1-1. 매일매일 글자 장식 (PNG)
          _buildTransformedImage(imgAo1, isSvg: false, left: 111.58, top: 36, width: 42, height: 42, angle: 0),
          _buildTransformedImage(imgDlf1, isSvg: false, left: 148.02, top: 40, width: 42, height: 42, angle: 0),
          _buildTransformedImage(imgAo1, isSvg: false, left: 185.02, top: 45.04, width: 42, height: 42, angle: 0),
          _buildTransformedImage(imgDlf1, isSvg: false, left: 221.42, top: 49, width: 42, height: 42, angle: 0),
          
          // 2. 별 장식들 (SVG) - React 코드 기반 완벽 동기화
          _buildTransformedImage(imgStar11, isSvg: true, left: 211, top: 23, width: 11, height: 11, angle: 0), // Star 11 (star-top-small-1)
          _buildTransformedImage(imgStar12, isSvg: true, left: 219, top: 30, width: 15, height: 15, angle: 0), // Star 12 (star-top-small-2)
          _buildTransformedImage(imgStar13, isSvg: true, left: 58, top: 179, width: 10, height: 10, angle: 0), // Star 13 (star-mid-left)
          _buildTransformedImage(imgStar8, isSvg: true, left: 303, top: 207, width: 22, height: 22, angle: 0), // Star 8 (star-mid-right-1)
          _buildTransformedImage(imgStar9, isSvg: true, left: 323, top: 204, width: 13, height: 13, angle: 0), // Star 9 (star-mid-right-2)
          _buildTransformedImage(imgStar16, isSvg: true, left: 48, top: 425, width: 9, height: 9, angle: 0), // Star 16 (star-bottom-left-2)
          _buildTransformedImage(imgStar13, isSvg: true, left: 58, top: 436, width: 10, height: 10, angle: 0), // Star 15 (star-bottom-left-1)
          _buildTransformedImage(imgStar12, isSvg: true, left: 301, top: 512, width: 15, height: 15, angle: 0), // Star 14 (star-bottom-right)
          
          // 3. 코인 장식들 (PNG)
          _buildTransformedImage(imgCoin51, isSvg: false, left: 30.22, top: 20.7, width: 22.67, height: 29.16, angle: 30.07),
          _buildTransformedImage(imgCoin41, isSvg: false, left: 308.52, top: 57.3, width: 27.53, height: 28.66, angle: 35.4),
          _buildTransformedImage(imgCoin11, isSvg: false, left: 67.97, top: 180.84, width: 27.02, height: 27.02, angle: -23.78),
          
          // 4. 큰 보라색 도장 장식 (stamp 1) - 3D 이미지이므로 PNG로 처리
          _buildTransformedImage(imgStamp1, isSvg: false, left: 235.49, top: 183.15, width: 51.67, height: 66.74, angle: 12.12),

          // 5. 메인 3D 타이틀 (가운데 정렬)
          Positioned(
            top: 65.88,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 260,
                height: 107,
                child: Image.network(imgCheckTitle, fit: BoxFit.contain),
              ),
            ),
          ),

          // 6 & 7. 서브 헤드라인 및 기간 뱃지 (간격 17px)
          Positioned(
            top: 182, // Figma 기준 Text의 bounding box top
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  '찍을수록 쏟아지는 리워드!',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.66,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 17), // 피그마 실측 간격
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF30343C),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Text(
                    '2026.4.1~4.30',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 8. 보상 마일스톤 (7일, 14일, ...)
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
                    runSpacing: 36,
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
    );
  }

  // 헬퍼 메서드: 각도 회전과 절대 좌표 배치를 위한 위젯 생성기
  Widget _buildTransformedImage(String url,
      {required bool isSvg,
      required double left,
      required double top,
      required double width,
      required double height,
      required double angle}) {
    final isLocalAsset = url.startsWith('assets/');
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: angle * (3.1415926535897932 / 180),
        child: isSvg 
            ? (isLocalAsset 
                ? SvgPicture.asset(url, fit: BoxFit.contain)
                : SvgPicture.network(url, fit: BoxFit.contain, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))
            : (isLocalAsset
                ? Image.asset(url, fit: BoxFit.contain)
                : Image.network(url, fit: BoxFit.contain)),
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
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF30343C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  children: [
                    const Text(
                      '이번 달 출석 ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF51565F),
                      ),
                    ),
                    Text(
                      '${_attendedDays.length}일',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7F4FFF),
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
              // 7일, 14일, 21일 등 특정 일자에 리워드 뱃지 표시 로직
              final isRewardDay = !isOutsideMonth && (date.day % 7 == 0); 
              
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 날짜 텍스트 (출석 완료 시에는 도장으로 덮어지므로 숨김)
                  if (!isAttended)
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: isOutsideMonth ? FontWeight.w500 : FontWeight.w600,
                        color: isOutsideMonth
                            ? const Color(0xFFD6DBE4)
                            : const Color(0xFF6C737F),
                      ),
                    ),
                  // 스탬프 오버레이
                  if (!isOutsideMonth && (isAttended || isRewardDay || isToday))
                    CalendarStamp(
                      isAttended: isAttended,
                      showToday: isToday,
                      showReward: isRewardDay && !isAttended, // 미출석인 보상날짜에만 뱃지 표시(예시)
                      rewardPoint: (date.day ~/ 7) * 100,
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
          color: const Color(0xFF7F4FFF),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('출석이 완료되었습니다!')),
              );
            },
            child: const Center(
              child: Text(
                '오늘 출석하기',
                style: TextStyle(
                  fontFamily: 'Pretendard',
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
      color: const Color(0xFF3B3E51), // 스크린샷 배경색 (임의 지정)
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        children: [
          // 타이틀 (친구에게 소문내기)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.pets, color: Colors.white, size: 24), // TODO: 에셋으로 교체
              SizedBox(width: 8),
              Text(
                '친구에게',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.campaign, color: Colors.pinkAccent, size: 32), // 메가폰 아이콘 임시
              SizedBox(width: 8),
              Text(
                '소문내기',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 공유 버튼 묶음 박스
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareIcon(Icons.chat_bubble, const Color(0xFFFFE812), '카카오', Colors.black),
                _buildShareIcon(Icons.camera_alt, const Color(0xFFE1306C), '인스타', Colors.white),
                _buildShareIcon(Icons.link, const Color(0xFF6C737F), '링크복사', Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareIcon(IconData icon, Color bgColor, String label, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF30343C),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF4F6F8), // 회색 배경
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '이벤트 유의사항',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF30343C),
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
    path.lineTo(p3.dx, p3.dy);
    
    // 오른쪽 아래로 향하는 부드러운 반원 커브 곡선 (반지름 63)
    path.arcToPoint(
      Offset(p3.dx, y2), 
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
