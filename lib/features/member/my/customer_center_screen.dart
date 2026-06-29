import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/page_header.dart';
import '../data/board_repository.dart';
import '../domain/notice_models.dart';
import '../domain/qna_models.dart';
import 'qna_create_screen.dart';
import 'qna_detail_screen.dart';

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

  // Notice List and Pagination State
  final List<NoticeItem> _noticeItems = [];
  bool _noticeIsLoading = false;
  bool _noticeHasNext = true;
  String? _noticeNextCursor;
  String? _noticeError;
  final ScrollController _noticeScrollController = ScrollController();

  // Notice Details Cache and Loading States
  final Map<String, NoticeDetail> _noticeDetails = {};
  final Set<String> _loadingDetails = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch QnAs & Notices on init
    _qnaScrollController.addListener(_onQnaScroll);
    _noticeScrollController.addListener(_onNoticeScroll);
    _fetchQnas();
    _fetchNotices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qnaScrollController.dispose();
    _noticeScrollController.dispose();
    super.dispose();
  }

  void _onQnaScroll() {
    if (_qnaScrollController.position.pixels >= _qnaScrollController.position.maxScrollExtent - 200) {
      if (!_qnaIsLoading && _qnaHasNext) {
        _fetchQnas();
      }
    }
  }

  void _onNoticeScroll() {
    if (_noticeScrollController.position.pixels >= _noticeScrollController.position.maxScrollExtent - 200) {
      if (!_noticeIsLoading && _noticeHasNext) {
        _fetchNotices();
      }
    }
  }

  Future<void> _fetchNotices({bool isRefresh = false}) async {
    if (_noticeIsLoading) return;

    setState(() {
      _noticeIsLoading = true;
      _noticeError = null;
      if (isRefresh) {
        _noticeItems.clear();
        _noticeNextCursor = null;
        _noticeHasNext = true;
        _expandedIndex = -1;
      }
    });

    try {
      final repository = ref.read(boardRepositoryProvider);
      final response = await repository.getNoticeList(
        cursor: _noticeNextCursor,
        limit: 20,
      );

      setState(() {
        _noticeItems.addAll(response.items);
        _noticeHasNext = response.hasNext;
        _noticeNextCursor = response.nextCursor;
        _noticeIsLoading = false;
      });
    } catch (e) {
      debugPrint('[CustomerCenter] Notice 로딩 실패 에러: $e');
      setState(() {
        _noticeError = '공지사항 목록을 불러오는데 실패했습니다.';
        _noticeIsLoading = false;
      });
    }
  }

  Future<void> _fetchNoticeDetail(String boardId) async {
    if (_loadingDetails.contains(boardId)) return;

    setState(() {
      _loadingDetails.add(boardId);
    });

    try {
      final repository = ref.read(boardRepositoryProvider);
      final detail = await repository.getNoticeDetail(boardId);
      setState(() {
        _noticeDetails[boardId] = detail;
        _loadingDetails.remove(boardId);
      });
    } catch (e) {
      debugPrint('[CustomerCenter] 공지 상세 로딩 실패: $e');
      setState(() {
        _loadingDetails.remove(boardId);
      });
    }
  }

  Future<void> _downloadFileToDevice(NoticeFile file) async {
    try {
      if (!mounted) return;
      ToastUtil.show(context, '다운로드를 시작합니다.');

      final bytes = await ref.read(boardRepositoryProvider).downloadFile(file.fileId);
      
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getDownloadsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      directory ??= await getApplicationDocumentsDirectory();

      String filePath = "${directory.path}/${file.originName}";
      File f = File(filePath);
      
      int counter = 1;
      final extensionIndex = file.originName.lastIndexOf('.');
      final nameWithoutExt = extensionIndex != -1 ? file.originName.substring(0, extensionIndex) : file.originName;
      final ext = extensionIndex != -1 ? file.originName.substring(extensionIndex) : '';
      
      while (await f.exists()) {
        filePath = "${directory.path}/${nameWithoutExt}_$counter$ext";
        f = File(filePath);
        counter++;
      }

      await f.writeAsBytes(bytes);

      if (mounted) {
        ToastUtil.show(context, '다운로드가 완료되었습니다.\n저장 경로: ${f.path}');
      }
    } catch (e) {
      debugPrint('[FileDownloadError] error: $e');
      if (mounted) {
        ToastUtil.show(context, '다운로드에 실패했습니다: $e');
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
      debugPrint('[CustomerCenter] QnA 로딩 실패 에러: $e');
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
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
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
    if (_noticeIsLoading && _noticeItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7F4FFF),
        ),
      );
    }

    if (_noticeError != null && _noticeItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _noticeError!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                color: Color(0xFF6C737F),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _fetchNotices(isRefresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F4FFF),
              ),
              child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_noticeItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchNotices(isRefresh: true),
        color: const Color(0xFF7F4FFF),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: Color(0xFFA2ADBE),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '등록된 공지사항이 없습니다.',
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchNotices(isRefresh: true),
      color: const Color(0xFF7F4FFF),
      child: ListView.builder(
        controller: _noticeScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: _noticeItems.length + (_noticeHasNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _noticeItems.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7F4FFF),
                ),
              ),
            );
          }

          final notice = _noticeItems[index];
          final isExpanded = _expandedIndex == index;
          final detail = _noticeDetails[notice.boardId];
          final isDetailLoading = _loadingDetails.contains(notice.boardId);

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
                    if (isExpanded) {
                      setState(() {
                        _expandedIndex = -1;
                      });
                    } else {
                      setState(() {
                        _expandedIndex = index;
                      });
                      if (detail == null) {
                        _fetchNoticeDetail(notice.boardId);
                      }
                    }
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
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: notice.title),
                                  if (_isRecentNotice(notice.regDt)) ...[
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Container(
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
                                                height: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
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
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(notice.regDt),
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
                    child: Builder(
                      builder: (context) {
                        if (isDetailLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(
                                color: Color(0xFF7F4FFF),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }

                        if (detail == null) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                '내용을 불러오지 못했습니다.',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  color: Color(0xFF87909E),
                                ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HtmlWidget(
                              detail.content,
                              textStyle: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w400, // Regular
                                color: Color(0xFF51565F),
                                height: 1.4,
                                letterSpacing: -0.66,
                              ),
                            ),
                            if (detail.files.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                '첨부파일 ${detail.files.length}',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF51565F),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...detail.files.map((file) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
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
                                                file.originName,
                                                style: const TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF51565F),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                file.fileSize,
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
                                          icon: const Icon(Icons.file_download_outlined, color: Color(0xFF6C737F)),
                                          onPressed: () => _downloadFileToDevice(file),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isRecentNotice(String regDtString) {
    try {
      final regDt = DateTime.parse(regDtString.replaceAll(' ', 'T'));
      final now = DateTime.now();
      final difference = now.difference(regDt).inDays;
      return difference < 3; // "New" badge for 3 days
    } catch (e) {
      return false;
    }
  }

  Widget _buildQnaTab() {
    Widget body;

    if (_qnaIsLoading && _qnaItems.isEmpty) {
      body = const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7F4FFF),
        ),
      );
    } else if (_qnaError != null && _qnaItems.isEmpty) {
      body = Center(
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
    } else {
      body = RefreshIndicator(
        onRefresh: () => _fetchQnas(isRefresh: true),
        color: const Color(0xFF7F4FFF),
        child: _qnaItems.isEmpty
            ? _buildEmptyQnaState()
            : ListView.builder(
                controller: _qnaScrollController,
                padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
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
      );
    }

    return Column(
      children: [
        Expanded(child: body),
        _buildBottomActionButton(),
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
        onTap: () async {
          final refreshNeeded = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => QnaDetailScreen(boardQnaId: qna.boardQnaId),
            ),
          );
          if (refreshNeeded == true) {
            _fetchQnas(isRefresh: true);
          }
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
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 12,
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF7F4FFF),
          borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          child: const Center(
            child: Text(
              '1:1 문의하기',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
