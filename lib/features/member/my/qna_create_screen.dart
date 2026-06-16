import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/page_header.dart';
import '../data/board_repository.dart';
import '../data/file_repository.dart';
import '../domain/qna_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class QnaCreateScreen extends ConsumerStatefulWidget {
  final QnaDetail? qnaToEdit;
  const QnaCreateScreen({super.key, this.qnaToEdit});

  @override
  ConsumerState<QnaCreateScreen> createState() => _QnaCreateScreenState();
}

class _QnaCreateScreenState extends ConsumerState<QnaCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String? _selectedTypeCode;
  bool _isLoading = false;
  String? _errorMessage;
  final List<Map<String, String>> _attachedFiles = [];

  final List<Map<String, String>> _qnaTypes = [
    {'code': 'PAYMENT', 'label': '결제'},
    {'code': 'QUESTIONNAIRE', 'label': '문진'},
    {'code': 'REWARD', 'label': '리워드'},
    {'code': 'SUGGESTION', 'label': '제안'},
    {'code': 'USER', 'label': '회원'},
    {'code': 'ETC', 'label': '기타'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.qnaToEdit != null) {
      _titleController.text = widget.qnaToEdit!.title;
      _contentController.text = widget.qnaToEdit!.content;
      _selectedTypeCode = widget.qnaToEdit!.qnaTypeCode;
      for (final file in widget.qnaToEdit!.files) {
        _attachedFiles.add({
          'fileId': file.fileId,
          'name': file.originName,
          'size': file.fileSize,
          'type': _detectFileType(file.originName),
        });
      }
    }
  }

  String _detectFileType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return 'image';
    }
    return 'file';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String? _getSelectedTypeLabel() {
    if (_selectedTypeCode == null) return null;
    final type = _qnaTypes.firstWhere((element) => element['code'] == _selectedTypeCode);
    return type['label'];
  }

  void _showTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '문의 유형',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF30343C),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF30343C), size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _qnaTypes.map((type) {
                          final isSelected = _selectedTypeCode == type['code'];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTypeCode = type['code'];
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xFFE8EBF1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    type['label']!,
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: const Color(0xFF30343C),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF7F4FFF),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    if (_attachedFiles.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('첨부파일은 최대 3개까지 등록 가능합니다.')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        final bytes = await image.readAsBytes();
        
        final fileRepository = ref.read(fileRepositoryProvider);
        final fileResponse = await fileRepository.uploadFile(
          fileBytes: bytes,
          filename: image.name,
        );

        final String? fileId = fileResponse['fileId'];
        
        if (fileId != null) {
          final sizeInMb = bytes.length / (1024 * 1024);
          final sizeText = '${sizeInMb.toStringAsFixed(1)} MB';

          setState(() {
            _attachedFiles.add({
              'fileId': fileId,
              'name': image.name,
              'path': image.path,
              'size': sizeText,
              'type': 'image',
            });
            _isLoading = false;
          });
          if (mounted) {
            ToastUtil.show(context, '파일이 첨부되었습니다.');
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Camera pick & upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 업로드에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_attachedFiles.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('첨부파일은 최대 3개까지 등록 가능합니다.')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        final bytes = await image.readAsBytes();
        
        final fileRepository = ref.read(fileRepositoryProvider);
        final fileResponse = await fileRepository.uploadFile(
          fileBytes: bytes,
          filename: image.name,
        );

        final String? fileId = fileResponse['fileId'];
        
        if (fileId != null) {
          final sizeInMb = bytes.length / (1024 * 1024);
          final sizeText = '${sizeInMb.toStringAsFixed(1)} MB';

          setState(() {
            _attachedFiles.add({
              'fileId': fileId,
              'name': image.name,
              'path': image.path,
              'size': sizeText,
              'type': 'image',
            });
            _isLoading = false;
          });
          if (mounted) {
            ToastUtil.show(context, '파일이 첨부되었습니다.');
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Gallery pick & upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 업로드에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    if (_attachedFiles.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('첨부파일은 최대 3개까지 등록 가능합니다.')),
      );
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        final path = platformFile.path;
        
        if (path != null) {
          setState(() {
            _isLoading = true;
          });

          final file = io.File(path);
          final bytes = await file.readAsBytes();

          final double sizeInMb = bytes.length / (1024 * 1024);
          if (sizeInMb > 30.0) {
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('첨부파일은 최대 30MB까지 등록 가능합니다.')),
              );
            }
            return;
          }

          final fileRepository = ref.read(fileRepositoryProvider);
          final fileResponse = await fileRepository.uploadFile(
            fileBytes: bytes,
            filename: platformFile.name,
          );

          final String? fileId = fileResponse['fileId'];

          if (fileId != null) {
            final sizeText = '${sizeInMb.toStringAsFixed(1)} MB';

            setState(() {
              _attachedFiles.add({
                'fileId': fileId,
                'name': platformFile.name,
                'path': path,
                'size': sizeText,
                'type': 'file',
              });
              _isLoading = false;
            });
            if (mounted) {
              ToastUtil.show(context, '파일이 첨부되었습니다.');
            }
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('File pick & upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 업로드에 실패했습니다: $e')),
        );
      }
    }
  }

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 52,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DBE4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildAttachmentItem(
                      icon: Icons.photo_camera_outlined,
                      label: '사진 촬영',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildAttachmentItem(
                      icon: Icons.photo_outlined,
                      label: '앨범 선택',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildAttachmentItem(
                      icon: Icons.insert_drive_file_outlined,
                      label: '파일 선택',
                      onTap: () {
                        Navigator.pop(context);
                        _pickFile();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF87909E),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF51565F),
                letterSpacing: -0.66,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitQna() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (_selectedTypeCode == null || title.isEmpty || content.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fileIds = _attachedFiles
          .map((file) => file['fileId'])
          .whereType<String>()
          .toList();

      final repository = ref.read(boardRepositoryProvider);
      if (widget.qnaToEdit != null) {
        await repository.updateQna(
          id: widget.qnaToEdit!.boardQnaId,
          qnaTypeCode: _selectedTypeCode!,
          title: title,
          content: content,
          fileIds: fileIds.isEmpty ? null : fileIds,
        );
        if (mounted) {
          ToastUtil.show(context, '1:1 문의가 성공적으로 수정되었습니다.');
          Navigator.of(context).pop(true);
        }
      } else {
        await repository.createQna(
          qnaTypeCode: _selectedTypeCode!,
          title: title,
          content: content,
          fileIds: fileIds.isEmpty ? null : fileIds,
        );
        if (mounted) {
          ToastUtil.show(context, '1:1 문의가 성공적으로 등록되었습니다.');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = widget.qnaToEdit != null
            ? '문의 수정에 실패했습니다. 다시 시도해 주세요.'
            : '문의 등록에 실패했습니다. 다시 시도해 주세요.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _titleController.text.trim();
    final contentText = _contentController.text.trim();
    final isSubmitEnabled = _selectedTypeCode != null &&
        titleText.isNotEmpty &&
        contentText.isNotEmpty &&
        !_isLoading;
    final selectedLabel = _getSelectedTypeLabel();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NurimPageHeader(
              title: widget.qnaToEdit != null ? '1:1 문의 수정' : '문의하기',
              onBackPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '문의유형',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF30343C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _showTypeBottomSheet,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE8EBF1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedLabel ?? '문의 유형을 선택해 주세요.',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 15,
                                color: selectedLabel != null ? const Color(0xFF30343C) : const Color(0xFFA2ADBE),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF87909E),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
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
                        hintText: '제목을 입력해 주세요.',
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
                      '내용',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF30343C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        TextField(
                          controller: _contentController,
                          onChanged: (text) => setState(() {}),
                          maxLines: 8,
                          minLines: 6,
                          maxLength: 1200,
                          decoration: InputDecoration(
                            hintText: '내용을 입력해 주세요.',
                            hintStyle: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 15,
                              color: Color(0xFFA2ADBE),
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FB),
                            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
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
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Text(
                            '${_contentController.text.length}/1200',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFA2ADBE),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '첨부파일',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF30343C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF7F4FFF),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: _showAttachmentBottomSheet,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '파일 첨부',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7F4FFF),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.add,
                                color: Color(0xFF7F4FFF),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_attachedFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Column(
                        children: _attachedFiles.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          final isImage = file['type'] == 'image';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE8EBF1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                                  color: const Color(0xFF87909E),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        file['name']!,
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF30343C),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        file['size']!,
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 11,
                                          color: Color(0xFF87909E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                 InkWell(
                                  onTap: () async {
                                    final fileId = file['fileId'];
                                    if (fileId != null) {
                                      try {
                                        setState(() {
                                          _isLoading = true;
                                        });
                                        await ref.read(fileRepositoryProvider).deleteFile(fileId);
                                      } catch (e) {
                                        debugPrint('File delete error: $e');
                                      } finally {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                    setState(() {
                                      _attachedFiles.removeAt(index);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close,
                                      color: Color(0xFF87909E),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF87909E),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '첨부파일은 최대 3개, 30MB까지 등록 가능합니다.',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF87909E),
                            ),
                          ),
                        ),
                      ],
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
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 4,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 12
                    : 24,
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
