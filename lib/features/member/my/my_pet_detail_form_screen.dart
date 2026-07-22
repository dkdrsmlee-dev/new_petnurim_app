import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_routes.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/photo_source_sheet.dart';
import '../domain/pet_breed.dart';
import '../../../core/theme/app_colors.dart';

class MyPetDetailFormScreen extends ConsumerStatefulWidget {
  final String petType; // 'DOG' 또는 'CAT'

  const MyPetDetailFormScreen({
    super.key,
    required this.petType,
  });

  @override
  ConsumerState<MyPetDetailFormScreen> createState() => _MyPetDetailFormScreenState();
}

class _MyPetDetailFormScreenState extends ConsumerState<MyPetDetailFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _profileImagePath;
  String? _selectedBreed;
  String? _selectedBreedId;
  bool _isNextButtonEnabled = false;


  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    _validateForm();
  }

  void _validateForm() {
    final name = _nameController.text.trim();
    setState(() {
      _isNextButtonEnabled = name.isNotEmpty;
    });
  }

  // 사진 등록 바텀 시트 호출
  void _showPhotoBottomSheet() {
    showPhotoSourceSheet(
      context,
      onCamera: () => _pickImage(ImageSource.camera),
      onGallery: () => _pickImage(ImageSource.gallery),
    );
  }

  // 이미지 선택 처리
  Future<void> _pickImage(ImageSource source) async {
    final path = await pickImagePath(context, source);
    if (path != null) {
      setState(() {
        _profileImagePath = path;
      });
    }
  }

  // 품종 선택 화면 이동
  Future<void> _navigateToBreedSelect() async {
    final selected = await context.push<PetBreed>(
      Uri(
        path: AppRoutes.myPetBreedSelect,
        queryParameters: {'petType': widget.petType},
      ).toString(),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedBreed = selected.breedNameKor;
        _selectedBreedId = selected.petBreedId;
        _validateForm();
      });
    }
  }

  void _showCancelDialog() {
    final isDirty = _nameController.text.trim().isNotEmpty ||
        _profileImagePath != null ||
        _selectedBreed != null;

    if (!isDirty) {
      context.pop();
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return EdgeButtonDialog(
          title: '등록을 중단하시겠어요?',
          content: '지금까지 입력한 정보는\n저장되지 않아요.',
          cancelText: '취소',
          confirmText: '확인',
          onConfirm: () {
            context.go(AppRoutes.myPetList);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '마이 펫 추가',
        showDivider: false,
        onBackPressed: _showCancelDialog,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단 질문 텍스트
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        '우리 아이의 첫 프로필을\n만들어 볼까요?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700, // Bold
                          letterSpacing: -0.66,
                          color: AppColors.textStrong,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 프로필 사진 등록 버튼 (100px 원형)
                    Center(
                      child: GestureDetector(
                        onTap: _showPhotoBottomSheet,
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            children: [
                              // 원형 사진/플레이스홀더 영역
                              Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.bgGray,
                                ),
                                child: ClipOval(
                                  child: _profileImagePath != null
                                      ? Image.file(
                                          File(_profileImagePath!),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : Stack(
                                          children: [
                                            Positioned(
                                              left: 20,
                                              top: 22.37,
                                              width: 60,
                                              child: SvgPicture.asset(
                                                'assets/images/ic_pet_foot_default.svg',
                                                fit: BoxFit.fitWidth,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              // 우측 하단 카메라 오버레이 버튼
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.textDisabled,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      size: 18,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 이름 입력 필드 (필수)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NurimFieldLabel('이름', isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textStrong,
                          ),
                          decoration: InputDecoration(
                            hintText: '아이의 이름을 알려주세요.',
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              color: AppColors.placeholder,
                              letterSpacing: -0.66,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 품종 선택 필드 (선택)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NurimFieldLabel('품종'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _navigateToBreedSelect,
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedBreed ?? '품종을 선택해 주세요.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedBreed != null ? AppColors.textStrong : AppColors.placeholder,
                                      letterSpacing: -0.66,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.textDisabled,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 하단 버튼 영역 (취소 vs 다음)
            NurimBottomActionBar(
              secondaryLabel: '취소',
              onSecondaryPressed: _showCancelDialog,
              primaryLabel: '다음',
              primaryEnabled: _isNextButtonEnabled,
              onPrimaryPressed: () {
                context.push(
                  Uri(
                    path: AppRoutes.myPetStoryForm,
                    queryParameters: {
                      'petType': widget.petType,
                      'name': _nameController.text.trim(),
                      'breed': _selectedBreed,
                      'breedId': _selectedBreedId,
                      'profileImagePath': _profileImagePath,
                    },
                  ).toString(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
