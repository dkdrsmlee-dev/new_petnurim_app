import 'package:flutter/material.dart';
import '../../core/widgets/nurim_text_card.dart';
import '../../core/widgets/page_header.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Mock Notification Data matching the Figma design and requirements
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': '[운영 공지] 서비스 점검 안내',
      'date': '2026.04.08',
      'isNew': true,
      'isExpanded': false,
      'hasMore': true,
      'content': '안녕하세요. [Web 3.0]입니다.\n보다 안정적인 서비스 제공을 위해 아래와 같이 시스템 점검이 진행될 예정입니다.',
      'bullets': [
        '점검 일시: 2026년 00월 00일 (00:00 ~ 02:00)',
        '점검 내용: 서버 안정화 및 기능 개선 작업',
      ]
    },
    {
      'title': '[안내] 반려동물 프로필 등록 완료',
      'date': '2026.04.07',
      'isNew': true,
      'isExpanded': false,
      'hasMore': false,
      'content': '우리 아이의 반려동물 프로필 등록이 성공적으로 완료되었습니다. 마이페이지에서 프로필 정보를 확인하고 다양한 펫 서비스를 즐겨보세요!',
      'bullets': null,
    },
    {
      'title': '[이벤트] 친구 초대 리워드 100PR 지급 완료',
      'date': '2026.04.05',
      'isNew': false,
      'isExpanded': false,
      'hasMore': false,
      'content': '친구 초대 링크를 통해 친구가 가입하여 감사 리워드로 100PR이 지급되었습니다. 지급된 포인트는 포인트 히스토리에서 바로 확인하실 수 있습니다.',
      'bullets': null,
    }
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
            // Page Header with back button and settings gear
            NurimPageHeader(
              title: '알림 센터',
              onBackPressed: () => Navigator.of(context).pop(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Color(0xFF30343C)),
                  onPressed: () {
                    // Navigate to settings if needed
                  },
                ),
              ],
            ),

            // 모두읽음 버튼 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _markAllAsRead,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '모두읽음',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w400, // Regular
                        color: Color(0xFF87909E),
                        letterSpacing: -0.66,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 알림 목록 영역
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  final bullets = item['bullets'] != null ? List<String>.from(item['bullets'] as List) : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: NurimTextCard(
                      title: item['title'] as String,
                      content: item['content'] as String,
                      date: item['date'] as String,
                      isUnread: item['isNew'] as bool,
                      isExpanded: item['isExpanded'] as bool,
                      hasMore: item['hasMore'] as bool,
                      bullets: bullets,
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
