import 'package:flutter/material.dart';
import '../../core/widgets/nurim_text_card.dart';
import '../../core/widgets/page_header.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Figma `알림센터_푸시알림_목록`(514:6335)의 4개 상태(Short/Truncated/
  // Expanded/제목 2줄 Expanded)를 그대로 재현한 검수용 목업 데이터.
  // 백엔드 알림 API 미제공 구간이라 서버 연동 시 이 목록을 교체한다.
  final List<Map<String, dynamic>> _notifications = [
    // Short — 더보기 버튼 없음
    {
      'title': '[운영 공지]서비스 점검 안내',
      'date': '2026.04.08',
      'isNew': true,
      'isExpanded': false,
      'hasMore': false,
      'content': '안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.',
      'bullets': null,
      'tailContent': null,
    },
    // Truncated — 제목 2줄 말줄임 + 더보기
    {
      'title': '[운영 공지]서비스 점검 안내 공지사항 두 줄 이상시에는 두 줄 까지 보여주고 그 이상은 점으로 보여요',
      'date': '2026.04.08',
      'isNew': true,
      'isExpanded': false,
      'hasMore': true,
      'content': '안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.',
      'bullets': [
        '점검 일시: 2026년 00월 00일 (00:00 ~ 02:00)',
        '점검 내용: 서버 안정화 및 기능 개선 작업',
      ],
      'tailContent': '안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다. 안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.\n\n안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.',
    },
    // Expanded — 불릿 + 이어지는 장문 + 접기
    {
      'title': '[운영 공지]서비스 점검 안내',
      'date': '2026.04.08',
      'isNew': false,
      'isExpanded': true,
      'hasMore': true,
      'content': '안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.',
      'bullets': [
        '점검 일시: 2026년 00월 00일 (00:00 ~ 02:00)',
        '점검 내용: 서버 안정화 및 기능 개선 작업',
      ],
      'tailContent': '안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다. 안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.\n\n안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.',
    },
    // Expanded — 제목까지 2줄인 장문 케이스
    {
      'title': '[운영 공지]서비스 점검 안내 공지사항 두 줄 이상시에는 두 줄 까지 보여주고 그 이상은 점으로 보여요',
      'date': '2026.04.08',
      'isNew': false,
      'isExpanded': true,
      'hasMore': true,
      'content': '안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.',
      'bullets': [
        '점검 일시: 2026년 00월 00일 (00:00 ~ 02:00)',
        '점검 내용: 서버 안정화 및 기능 개선 작업',
      ],
      'tailContent': '안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다. 안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.\n\n안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.',
    },
  ];

  /// 모두 읽음 처리
  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isNew'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Page Header with back button and '모두읽음' button on the right
            NurimPageHeader(
              title: '알림 센터',
              onBackPressed: () => Navigator.of(context).pop(),
              actions: [
                TextButton(
                  onPressed: _markAllAsRead,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '모두읽음',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400, // Regular
                      color: AppColors.textSecondary,
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
              ],
            ),

            // 안내 바 (Figma 1140:10943) — 헤더 바로 아래 전체폭 회색 띠
            Container(
              width: double.infinity,
              color: AppColors.bgGray,
              padding: const EdgeInsets.all(16),
              child: const Text(
                '최근 30일 알림만 표시돼요.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: AppColors.textSecondary,
                  height: 1.4,
                  letterSpacing: -0.66,
                ),
              ),
            ),

            // 알림 목록 영역
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  final bullets = item['bullets'] != null ? List<String>.from(item['bullets'] as List) : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    // 알림 상세(Figma 푸시알림 403:25245)는 보류 상태라
                    // 카드 탭 시 준비 중 안내만 노출한다. 더보기/접기는
                    // 카드 내부 InkWell이 우선 처리하므로 영향받지 않는다.
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => ToastUtil.show(context, '준비 중인 기능입니다.'),
                      child: NurimTextCard(
                        title: item['title'] as String,
                        content: item['content'] as String,
                        date: item['date'] as String,
                        isUnread: item['isNew'] as bool,
                        isExpanded: item['isExpanded'] as bool,
                        hasMore: item['hasMore'] as bool,
                        bullets: bullets,
                        tailContent: item['tailContent'] as String?,
                        onExpandToggled: () {
                          setState(() {
                            final nextExpanded = !(item['isExpanded'] as bool);
                            item['isExpanded'] = nextExpanded;
                            // 펼쳤을 때 자동으로 안읽음 표시를 해제함
                            if (nextExpanded) {
                              item['isNew'] = false;
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
