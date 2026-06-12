import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/page_header.dart';
import '../data/board_repository.dart';
import '../domain/qna_models.dart';

class QnaDetailScreen extends ConsumerStatefulWidget {
  final String boardQnaId;
  const QnaDetailScreen({super.key, required this.boardQnaId});

  @override
  ConsumerState<QnaDetailScreen> createState() => _QnaDetailScreenState();
}

class _QnaDetailScreenState extends ConsumerState<QnaDetailScreen> {
  late Future<QnaDetail> _detailFuture;
  String? _token;

  @override
  void initState() {
    super.initState();
    _detailFuture = ref.read(boardRepositoryProvider).getQnaDetail(widget.boardQnaId);
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    if (mounted) {
      setState(() {
        _token = token;
      });
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

  String _getFileUrl(String fileId) {
    final config = ref.read(appConfigProvider);
    return config.apiUri('/api/v1/files/$fileId').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '1:1 문의',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: FutureBuilder<QnaDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '오류: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _detailFuture = ref
                                .read(boardRepositoryProvider)
                                .getQnaDetail(widget.boardQnaId);
                          });
                        },
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final qna = snapshot.data;
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
                              if (qna.files.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                _buildAttachmentList(qna.files),
                              ],
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
          },
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '첨부파일',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF30343C),
            letterSpacing: -0.66,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: files.map((file) => _buildAttachmentCard(file)).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachmentCard(QnaFile file) {
    final isImage = file.originName.toLowerCase().endsWith('.png') ||
        file.originName.toLowerCase().endsWith('.jpg') ||
        file.originName.toLowerCase().endsWith('.jpeg') ||
        file.originName.toLowerCase().endsWith('.gif') ||
        file.originName.toLowerCase().endsWith('.webp');

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EBF1), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: isImage
          ? _token != null
              ? Image.network(
                  _getFileUrl(file.fileId),
                  headers: {'Authorization': 'Bearer $_token'},
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFF87909E))),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                )
              : const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : const Center(child: Icon(Icons.insert_drive_file_outlined, color: Color(0xFF87909E), size: 32)),
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
