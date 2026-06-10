import 'package:flutter/material.dart';
import '../../../core/widgets/page_header.dart';

class CustomerCenterScreen extends StatefulWidget {
  const CustomerCenterScreen({super.key});

  @override
  State<CustomerCenterScreen> createState() => _CustomerCenterScreenState();
}

class _CustomerCenterScreenState extends State<CustomerCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _expandedIndex = -1; // Keep track of which notice is expanded

  // Mock Notices Data matching the Figma design details
  final List<Map<String, dynamic>> _notices = [
    {
      'title': '멤버십 신규 상품 출시',
      'date': '2026.04.12',
      'isNew': true,
      'content': '고객님의 더 나은 서비스 이용과 다양한 혜택 제공을 위해 새로운 멤버십 상품이 출시되었습니다.\n\n'
          '[신규 멤버십 상품 안내]\n'
          '이번에 새롭게 선보이는 멤버십은 이용 패턴에 따라 선택하실 수 있도록 구성되어있습니다.\n'
          '• Bronze\n   기본 혜택 중심의 입문형 멤버십\n'
          '• Silver\n   실속형 혜택과 다양한 리워드 제공\n'
          '• Gold\n   프리미엄 혜택과 차별화된 서비스 제공\n\n'
          '[주요 혜택]\n'
          '• 서비스 이용 시 리워드 적립\n'
          '• 멤버십 전용 이벤트 참여 기회 제공\n'
          '• 다양한 할인 및 혜택제공\n'
          '• 개인 맞춤형 서비스 추천\n\n'
          '[출시 일정]\n'
          '• 출시일: 2026년 00월 00일\n\n'
          '[이용 안내]\n'
          '• 멤버십은 마이페이지>멤버십 메뉴에서 가입하실 수 있습니다.\n'
          '• 멤버십은 마이페이지>멤버십 메뉴에서 가입하실 수 있습니다.\n\n'
          '앞으로도 더 나은 서비스와 다양한 혜택을 제공할 수 있도록 노력하겠습니다.\n감사합니다.',
      'fileName': '점검안내_0419.pdf',
      'fileSize': '1.2MB',
    },
    {
      'title': '멤버십 신규 상품 출시멤버십 신규 상품 출시 버전 멤버십 멤버십 제목 두줄 표기까지 가능합니다.',
      'date': '2026.04.12',
      'isNew': true,
      'content': '고객님의 더 나은 서비스 이용과 다양한 혜택 제공을 위해 새로운 멤버십 상품이 출시되었습니다.',
      'fileName': null,
      'fileSize': null,
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with left arrow and right settings gear
            NurimPageHeader(
              title: '고객센터',
              onBackPressed: () => Navigator.of(context).pop(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Color(0xFF30343C)),
                  onPressed: () {
                    // Navigate to settings page if needed
                  },
                ),
              ],
            ),
            // Custom TabBar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF30343C),
              unselectedLabelColor: const Color(0xFF6C737F),
              labelStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: const Color(0xFF7F4FFF),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: '공지사항'),
                Tab(text: '자주 묻는 질문'),
                Tab(text: '1 : 1 문의'),
              ],
            ),
            // Divider Line under TabBar
            Container(height: 1, color: const Color(0xFFD6DBE4)),
            // Tab contents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNoticeTabList(),
                  const Center(child: Text('자주 묻는 질문 목록')),
                  const Center(child: Text('1 : 1 문의하기')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeTabList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: _notices.length,
      itemBuilder: (context, index) {
        final notice = _notices[index];
        final isExpanded = _expandedIndex == index;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A51565F), // #51565F1A
                offset: Offset(0, 0),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header area
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedIndex = isExpanded ? -1 : index;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    notice['title'] as String,
                                    maxLines: isExpanded ? 5 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600, // SemiBold
                                      color: Color(0xFF30343C),
                                      height: 1.4,
                                      letterSpacing: -0.66,
                                    ),
                                  ),
                                ),
                                if (notice['isNew'] == true) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF7F4FFF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'N',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notice['date'] as String,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 13,
                                fontWeight: FontWeight.w400, // Regular
                                color: Color(0xFFA2ADBE),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: const Color(0xFF6C737F),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Body area (visible when expanded)
              if (isExpanded) ...[
                // Divider
                Container(height: 1, color: const Color(0xFFE8EBF1)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice['content'] as String,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w400, // Regular
                          color: Color(0xFF51565F),
                          height: 1.4,
                          letterSpacing: -0.66,
                        ),
                      ),
                      if (notice['fileName'] != null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          '첨부파일 1',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF51565F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notice['fileName'] as String,
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF51565F),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      notice['fileSize'] as String,
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF6C737F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.download, color: Color(0xFF6C737F)),
                                onPressed: () {
                                  // Download action logic
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
