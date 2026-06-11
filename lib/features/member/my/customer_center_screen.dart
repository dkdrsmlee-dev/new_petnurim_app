import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_header.dart';
import '../data/board_repository.dart';
import '../domain/qna_models.dart';
import 'qna_create_screen.dart';

class CustomerCenterScreen extends ConsumerStatefulWidget {
  const CustomerCenterScreen({super.key});

  @override
  ConsumerState<CustomerCenterScreen> createState() => _CustomerCenterScreenState();
}

class _CustomerCenterScreenState extends ConsumerState<CustomerCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _expandedIndex = -1; // Keep track of which notice is expanded

  // QnA List and Pagination State
  final List<QnaItem> _qnaItems = [];
  bool _qnaIsLoading = false;
  bool _qnaHasNext = true;
  String? _qnaNextCursor;
  String? _qnaError;
  final ScrollController _qnaScrollController = ScrollController();

  // Mock Notices Data matching the Figma design details
  final List<Map<String, dynamic>> _notices = [
    {
      'title': '멤버십 신규 상품 출시',
      'date': '2026.04.12',
      'isNew': true,
      'content': '고객님의 더 나은 service 이용과 다양한 혜택 제공을 위해 새로운 멤버십 상품이 출시되었습니다.\n\n'
          '[신규 멤버십 상품 안내]\n'
          '이번에 새롭게 선보이는 멤버십은 이용 패턴에 따라 선택하실 수 있도록 구성되어있습니다.\n'
          '• Bronze\n   기본 혜택 중심의 입문형 멤버십\n'
          '• Silver\n   실속형 혜택과 다양한 리워드 제공\n'
          '• Gold\n   프리미엄 혜택과 차별화된 service 제공\n\n'
          '[주요 혜택]\n'
          '• service 이용 시 리워드 적립\n'
          '• 멤버십 전용 이벤트 참여 기회 제공\n'
          '• 다양한 할인 및 혜택제공\n'
          '• 개인 맞춤형 service 추천\n\n'
          '[출시 일정]\n'
          '• 출시일: 2026년 00월 00일\n\n'
          '[이용 안내]\n'
          '• 멤버십은 마이페이지>멤버십 메뉴에서 가입하실 수 있습니다.\n'
          '• 멤버십은 마이페이지>멤버십 메뉴에서 가입하실 수 있습니다.\n\n'
          '앞으로도 더 나은 service와 다양한 혜택을 제공할 수 있도록 노력하겠습니다.\n감사합니다.',
      'fileName': '점검안내_0419.pdf',
      'fileSize': '1.2MB',
    },
    {
      'title': '멤버십 신규 상품 출시멤버십 신규 상품 출시 버전 멤버십 멤버십 제목 두줄 표기까지 가능합니다.',
      'date': '2026.04.12',
      'isNew': true,
      'content': '고객님의 더 나은 service 이용과 다양한 혜택 제공을 위해 새로운 멤버십 상품이 출시되었습니다.',
      'fileName': null,
      'fileSize': null,
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch QnAs on init
    _fetchQnas();

    // Listen for pagination scroll events
    _qnaScrollController.addListener(_onQnaScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qnaScrollController.dispose();
    super.dispose();
  }

  void _onQnaScroll() {
    if (_qnaScrollController.position.pixels >= _qnaScrollController.position.maxScrollExtent - 200) {
      if (!_qnaIsLoading && _qnaHasNext) {
        _fetchQnas();
      }
    }
  }

  Future<void> _fetchQnas({bool isRefresh = false}) async {
    if (_qnaIsLoading) return;

    setState(() {
      _qnaIsLoading = true;
      _qnaError = null;
      if (isRefresh) {
        _qnaItems.clear();
        _qnaNextCursor = null;
        _qnaHasNext = true;
      }
    });

    try {
      final repository = ref.read(boardRepositoryProvider);
      final response = await repository.getQnaList(
        cursor: _qnaNextCursor,
        limit: 20,
      );

      setState(() {
        _qnaItems.addAll(response.items);
        _qnaHasNext = response.hasNext;
        _qnaNextCursor = response.nextCursor;
        _qnaIsLoading = false;
      });
    } catch (e) {
      setState(() {
        _qnaError = '문의 내역을 불러오는데 실패했습니다.';
        _qnaIsLoading = false;
      });
    }
  }

  String _formatDate(String rawDate) {
    if (rawDate.length >= 10) {
      return rawDate.substring(0, 10).replaceAll('-', '.');
    }
    return rawDate;
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
                  _buildQnaTab(),
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

  Widget _buildQnaTab() {
    if (_qnaIsLoading && _qnaItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7F4FFF),
        ),
      );
    }

    if (_qnaError != null && _qnaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _qnaError!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                color: Color(0xFF6C737F),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _fetchQnas(isRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F4FFF),
              ),
              child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: () => _fetchQnas(isRefresh: true),
            color: const Color(0xFF7F4FFF),
            child: _qnaItems.isEmpty
                ? _buildEmptyQnaState()
                : ListView.builder(
                    controller: _qnaScrollController,
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
                    itemCount: _qnaItems.length + (_qnaHasNext ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _qnaItems.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7F4FFF),
                            ),
                          ),
                        );
                      }

                      final qna = _qnaItems[index];
                      return _buildQnaCard(qna);
                    },
                  ),
          ),
        ),
        // Bottom Action Button Area
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomActionButton(),
        ),
      ],
    );
  }

  Widget _buildEmptyQnaState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: Color(0xFFA2ADBE),
              ),
              SizedBox(height: 16),
              Text(
                '등록된 1:1 문의가 없습니다.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6C737F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQnaCard(QnaItem qna) {
    final isComplete = qna.processStatusCode == 'COMPLETE';
    final statusText = isComplete ? '답변완료' : '답변준비';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EBF1),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to detail page if implemented
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qna.title,
                      maxLines: 2,
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
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(qna.regDt),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFA2ADBE),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status Badge
              Container(
                width: 68,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isComplete ? Colors.white : const Color(0xFFE8EBF1),
                  borderRadius: BorderRadius.circular(13.5),
                  border: isComplete
                      ? Border.all(color: const Color(0xFF7F4FFF), width: 1)
                      : null,
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w600, // SemiBold
                    color: isComplete ? const Color(0xFF7F4FFF) : const Color(0xFF87909E),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionButton() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const QnaCreateScreen(),
            ),
          ).then((value) {
            if (value == true) {
              _fetchQnas(isRefresh: true);
            }
          });
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF7F4FFF),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            '1:1 문의하기',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w600, // SemiBold
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
