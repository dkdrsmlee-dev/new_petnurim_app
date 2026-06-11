import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/page_header.dart';
import '../data/board_repository.dart';

class QnaCreateScreen extends ConsumerStatefulWidget {
  const QnaCreateScreen({super.key});

  @override
  ConsumerState<QnaCreateScreen> createState() => _QnaCreateScreenState();
}

class _QnaCreateScreenState extends ConsumerState<QnaCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _selectedTypeCode = 'SERVICE';
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _qnaTypes = [
    {'code': 'SERVICE', 'label': '서비스 이용'},
    {'code': 'ACCOUNT', 'label': '계정/로그인'},
    {'code': 'BUG', 'label': '오류 신고'},
    {'code': 'OTHER', 'label': '기타'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitQna() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(boardRepositoryProvider);
      await repository.createQna(
        qnaTypeCode: _selectedTypeCode,
        title: title,
        content: content,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('1:1 문의가 성공적으로 등록되었습니다.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '문의 등록에 실패했습니다. 다시 시도해 주세요.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _titleController.text.trim();
    final contentText = _contentController.text.trim();
    final isSubmitEnabled = titleText.isNotEmpty && contentText.isNotEmpty && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            NurimPageHeader(
              title: '1:1 문의하기',
              onBackPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '문의 유형',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF30343C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _qnaTypes.map((type) {
                        final isSelected = _selectedTypeCode == type['code'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTypeCode = type['code']!;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF7F4FFF) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF7F4FFF) : const Color(0xFFE8EBF1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              type['label']!,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF6C737F),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '제목',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF30343C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      onChanged: (text) => setState(() {}),
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: '제목을 입력해주세요.',
                        hintStyle: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          color: Color(0xFFA2ADBE),
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE8EBF1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF7F4FFF)),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        color: Color(0xFF30343C),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '문의 내용',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF30343C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      onChanged: (text) => setState(() {}),
                      maxLines: 8,
                      minLines: 6,
                      decoration: InputDecoration(
                        hintText: '문의하실 내용을 상세히 적어주세요.',
                        hintStyle: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          color: Color(0xFFA2ADBE),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FB),
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE8EBF1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF7F4FFF)),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        color: Color(0xFF30343C),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom Sticky Submit Button
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitEnabled ? _submitQna : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubmitEnabled ? const Color(0xFF7F4FFF) : const Color(0xFFE8EBF1),
                    disabledBackgroundColor: const Color(0xFFE8EBF1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          '등록하기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isSubmitEnabled ? Colors.white : const Color(0xFF87909E),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
