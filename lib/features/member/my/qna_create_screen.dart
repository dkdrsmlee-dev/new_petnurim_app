import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/page_header.dart';
import '../data/board_repository.dart';
import '../data/file_repository.dart';
import '../domain/qna_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

class QnaCreateScreen extends ConsumerStatefulWidget {
  final QnaDetail? qnaToEdit;
  const QnaCreateScreen({super.key, this.qnaToEdit});

  @override
  ConsumerState<QnaCreateScreen> createState() => _QnaCreateScreenState();
}

class _QnaCreateScreenState extends ConsumerState<QnaCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  final _tooltipLayerLink = LayerLink();
  OverlayEntry? _tooltipOverlayEntry;
  
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
    _hideTooltip();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showTooltip() {
    if (_tooltipOverlayEntry != null) return;

    _tooltipOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideTooltip,
            child: const SizedBox.expand(),
          ),
          CompositedTransformFollower(
            link: _tooltipLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(0, 8),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A51565F),
                      blurRadius: 8,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '첨부파일 형식',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textStrong,
                            letterSpacing: -0.66,
                          ),
                        ),
                        GestureDetector(
                          onTap: _hideTooltip,
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'jpg, jpeg, png, gif, pdf, xls, xlsx, txt,\ndoc, docx, ppt, pptx, zip, hwp, hwpx',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.4,
                        letterSpacing: -0.66,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_tooltipOverlayEntry!);
  }

  void _hideTooltip() {
    _tooltipOverlayEntry?.remove();
    _tooltipOverlayEntry = null;
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
                            color: AppColors.textStrong,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textStrong, size: 24),
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
                                    color: AppColors.borderLight,
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
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.primary,
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
                    color: AppColors.border,
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
                      icon: SvgPicture.asset(
                        'assets/images/ic_camera.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          AppColors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: '사진 촬영',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildAttachmentItem(
                      icon: SvgPicture.asset(
                        'assets/images/ic_album.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          AppColors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: '앨범 선택',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildAttachmentItem(
                      icon: SvgPicture.asset(
                        'assets/images/ic_file_attach.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          AppColors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
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
    required Widget icon,
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
            SizedBox(
              width: 24,
              height: 24,
              child: Center(child: icon),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
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
      if (e is ApiException) {
        debugPrint('====================================');
        debugPrint('[QnA Error] ${widget.qnaToEdit != null ? "수정" : "등록"} 실패');
        debugPrint('HTTP 상태 코드: ${e.statusCode}');
        debugPrint('에러 코드: ${e.code}');
        debugPrint('에러 메시지: ${e.message}');
        debugPrint('상세 데이터: ${e.data}');
        debugPrint('====================================');
      } else {
        debugPrint('[QnA Error] 일반 예외 발생: $e');
      }
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
                        color: AppColors.textStrong,
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
                          color: AppColors.bgSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.borderLight,
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
                                color: selectedLabel != null ? AppColors.textStrong : AppColors.placeholder,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
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
                        color: AppColors.textStrong,
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
                          color: AppColors.placeholder,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.bgSoft,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '내용',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
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
                              color: AppColors.placeholder,
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.bgSoft,
                            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 15,
                            color: AppColors.textStrong,
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
                              color: AppColors.placeholder,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    CompositedTransformTarget(
                      link: _tooltipLayerLink,
                      child: Row(
                        children: [
                          const Text(
                            '첨부파일',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _showTooltip,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: AppColors.borderLight,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '?',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary,
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
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.add,
                                color: AppColors.primary,
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
                              color: AppColors.bgSoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                                  color: AppColors.textSecondary,
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
                                          color: AppColors.textStrong,
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
                                          color: AppColors.textSecondary,
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
                                      color: AppColors.textSecondary,
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
                          color: AppColors.textSecondary,
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
                              color: AppColors.textSecondary,
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
                    backgroundColor: isSubmitEnabled ? AppColors.primary : AppColors.borderLight,
                    disabledBackgroundColor: AppColors.borderLight,
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
                            color: isSubmitEnabled ? Colors.white : AppColors.textSecondary,
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
