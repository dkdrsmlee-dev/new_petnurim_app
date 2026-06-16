import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/page_header.dart';
import '../data/board_repository.dart';
import '../domain/qna_models.dart';
import 'qna_create_screen.dart';

class QnaDetailScreen extends ConsumerStatefulWidget {
  final String boardQnaId;
  const QnaDetailScreen({super.key, required this.boardQnaId});

  @override
  ConsumerState<QnaDetailScreen> createState() => _QnaDetailScreenState();
}

class _QnaDetailScreenState extends ConsumerState<QnaDetailScreen> {
  QnaDetail? _qnaDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await ref.read(boardRepositoryProvider).getQnaDetail(widget.boardQnaId);
      if (mounted) {
        setState(() {
          _qnaDetail = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }



  String _formatDate(String rawDate) {
    if (rawDate.length >= 10) {
      return rawDate.substring(0, 10).replaceAll('-', '.');
    }
    return rawDate;
  }

  String _getTypeLabel(String code) {
    switch (code) {
      case 'PAYMENT':
        return '결제';
      case 'QUESTIONNAIRE':
        return '문진';
      case 'REWARD':
        return '리워드';
      case 'SUGGESTION':
        return '제안';
      case 'USER':
        return '회원';
      case 'ETC':
        return '기타';
      default:
        return code;
    }
  }



  Future<void> _deleteQna() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '문의 삭제',
          style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '정말 이 1:1 문의를 삭제하시겠습니까?',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(fontFamily: 'Pretendard', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(fontFamily: 'Pretendard', color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });
        await ref.read(boardRepositoryProvider).deleteQna(widget.boardQnaId);
        if (mounted) {
          ToastUtil.show(context, '1:1 문의가 삭제되었습니다.');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제에 실패했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _editQna() async {
    if (_qnaDetail == null) return;
    
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QnaCreateScreen(qnaToEdit: _qnaDetail),
      ),
    );

    if (updated == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showActions = _qnaDetail != null && _qnaDetail!.processStatusCode != 'COMPLETE';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '1:1 문의',
        onBackPressed: () => Navigator.of(context).pop(),
        actions: showActions
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editQna();
                    } else if (value == 'delete') {
                      _deleteQna();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('수정하기', style: TextStyle(fontFamily: 'Pretendard')),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제하기', style: TextStyle(fontFamily: 'Pretendard', color: Colors.red)),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, color: Color(0xFF30343C)),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '오류: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    final qna = _qnaDetail;
    if (qna == null) {
      return const Center(
        child: Text(
          '문의 상세 내역이 없습니다.',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            color: Color(0xFF87909E),
          ),
        ),
      );
    }

    final isComplete = qna.processStatusCode == 'COMPLETE';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE8EBF1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Status Badge
                          _buildStatusBadge(isComplete),
                          const SizedBox(width: 8),
                          // Type & Date
                          Text(
                            _getTypeLabel(qna.qnaTypeCode),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFA2ADBE),
                              letterSpacing: -0.66,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '|',
                            style: TextStyle(
                              color: Color(0xFFE8EBF1),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(qna.regDt),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFA2ADBE),
                              letterSpacing: -0.66,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        qna.title,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF30343C),
                          height: 1.4,
                          letterSpacing: -0.66,
                        ),
                      ),
                    ],
                  ),
                ),
                // Question Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qna.content,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6C737F),
                          height: 1.4,
                          letterSpacing: -0.66,
                        ),
                      ),
                    ],
                  ),
                ),
                // Answer Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildAnswerBox(qna),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isComplete) {
    final statusText = isComplete ? '답변완료' : '답변준비';
    return Container(
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
          fontWeight: FontWeight.w600,
          color: isComplete ? const Color(0xFF7F4FFF) : const Color(0xFF87909E),
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildAttachmentList(List<QnaFile> files) {
    final imageFiles = files.where((file) => _isImageFile(file.originName)).toList();
    final docFiles = files.where((file) => !_isImageFile(file.originName)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageFiles.isNotEmpty) ...[
          ...imageFiles.map((file) => _buildImageAttachment(file)),
          if (docFiles.isNotEmpty) const SizedBox(height: 24),
        ],
        if (docFiles.isNotEmpty) ...[
          Text(
            '첨부파일 ${docFiles.length}',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF51565F),
              letterSpacing: -0.66,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: docFiles.map((file) => _buildDocAttachmentCard(file)).toList(),
          ),
        ],
      ],
    );
  }

  bool _isImageFile(String filename) {
    final lower = filename.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  Widget _buildImageAttachment(QnaFile file) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List>(
        future: ref.read(boardRepositoryProvider).downloadFile(file.fileId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 200,
              color: const Color(0xFFF8F9FB),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            debugPrint('[ImageDownloadError] fileId: ${file.fileId}, Error: ${snapshot.error}');
            return Container(
              height: 200,
              color: const Color(0xFFF8F9FB),
              child: const Center(
                child: Icon(Icons.broken_image_outlined, color: Color(0xFF87909E)),
              ),
            );
          }
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.fitWidth,
          );
        },
      ),
    );
  }

  Widget _buildDocAttachmentCard(QnaFile file) {
    final sizeText = file.fileSize.isNotEmpty ? file.fileSize : '0.0 MB';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EBF1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    color: Color(0xFF30343C),
                    letterSpacing: -0.66,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sizeText,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 11,
                    color: Color(0xFF87909E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              ToastUtil.show(context, '파일 다운로드를 시작합니다.');
            },
            icon: const Icon(
              Icons.file_download_outlined,
              color: Color(0xFF87909E),
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerBox(QnaDetail qna) {
    final hasAnswer = qna.answer != null;
    final answerDate = hasAnswer ? qna.answer!.regDt : qna.regDt;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Answer Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE8EBF1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'A.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F4FFF),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasAnswer ? '답변이 완료되었습니다.' : '답변이 준비 중입니다.',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF30343C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(answerDate),
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
          // Answer Content Body
          if (hasAnswer)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qna.answer!.content,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF51565F),
                      height: 1.4,
                      letterSpacing: -0.66,
                    ),
                  ),
                  if (qna.answer!.files.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAttachmentList(qna.answer!.files),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/img_response_waiting.png',
                      width: 132,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '담당자가 문의 내용을 확인하고 있어요.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF30343C),
                        letterSpacing: -0.66,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '잠시만 기다려 주세요.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6C737F),
                        letterSpacing: -0.66,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
