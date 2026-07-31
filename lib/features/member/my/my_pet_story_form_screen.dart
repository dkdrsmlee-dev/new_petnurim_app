import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/age_picker_sheet.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/nurim_date_picker.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/pet_codes.dart';

class MyPetStoryFormScreen extends ConsumerStatefulWidget {
  final String petType;
  final String name;
  final String? breed;
  final String? breedId;
  final String? profileImagePath;

  const MyPetStoryFormScreen({
    super.key,
    required this.petType,
    required this.name,
    this.breed,
    this.breedId,
    this.profileImagePath,
  });

  @override
  ConsumerState<MyPetStoryFormScreen> createState() => _MyPetStoryFormScreenState();
}

class _MyPetStoryFormScreenState extends ConsumerState<MyPetStoryFormScreen> {
  int? _selectedAge; // 나이 (1~20살)
  DateTime? _selectedDate; // 가족이 된 날
  String? _selectedGender; // 'MALE' ('남아') 또는 'FEMALE' ('여아')
  bool _isConfirmButtonEnabled = false;


  void _validateForm() {
    setState(() {
      _isConfirmButtonEnabled = _selectedAge != null && _selectedGender != null;
    });
  }

  // 나이 선택 바텀 시트 호출 (figma 226:14092)
  void _showAgeBottomSheet() {
    showAgePickerSheet(
      context,
      selectedAge: _selectedAge,
      onSelected: (age) {
        setState(() {
          _selectedAge = age;
        });
        _validateForm();
      },
    );
  }

  // 가족이 된 날 커스텀 Cupertino 휠 데이트 피커 바텀 시트 호출 (figma 226:14547)
  Future<void> _showDatePickerBottomSheet() async {
    final selected = await NurimDatePickerBottomSheet.show(
      context: context,
      title: '가족이 된 날',
      initialDate: _selectedDate ?? DateTime.now(),
      maximumDate: DateTime.now(),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  void _showCancelDialog() {
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
      appBar: const NurimPageHeader(
        title: '마이 펫 추가',
        showDivider: false,
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
                    // 상단 서브 타이틀
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        '아이의 이야기를\n조금 더 들려주세요.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.66,
                          color: AppColors.textStrong,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 나이 필드 (필수)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NurimFieldLabel('나이', isRequired: true),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showAgeBottomSheet,
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
                                    _selectedAge != null ? '$_selectedAge살' : '나이를 선택해 주세요.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedAge != null ? AppColors.textStrong : AppColors.placeholder,
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
                    const SizedBox(height: 24),
                    // 가족이 된 날 필드 (선택)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NurimFieldLabel('가족이 된 날'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showDatePickerBottomSheet,
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
                                    _selectedDate != null
                                        ? _selectedDate!.toKoreanDate()
                                        : '날짜를 선택해 주세요.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedDate != null ? AppColors.textStrong : AppColors.placeholder,
                                      letterSpacing: -0.66,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppColors.textDisabled,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 성별 필드 (필수)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NurimFieldLabel('성별', isRequired: true),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // 남아 토글 버튼
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedGender = PetGender.male;
                                  });
                                  _validateForm();
                                },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedGender == PetGender.male ? AppColors.primary : AppColors.border,
                                      width: _selectedGender == PetGender.male ? 1.5 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '남아',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: _selectedGender == PetGender.male ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedGender == PetGender.male ? AppColors.primary : AppColors.placeholder,
                                      letterSpacing: -0.66,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 여아 토글 버튼
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedGender = PetGender.female;
                                  });
                                  _validateForm();
                                },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedGender == PetGender.female ? AppColors.primary : AppColors.border,
                                      width: _selectedGender == PetGender.female ? 1.5 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '여아',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: _selectedGender == PetGender.female ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedGender == PetGender.female ? AppColors.primary : AppColors.placeholder,
                                      letterSpacing: -0.66,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 하단 버튼 영역 (취소 vs 확인)
            NurimBottomActionBar(
              secondaryLabel: '취소',
              onSecondaryPressed: _showCancelDialog,
              primaryLabel: '다음',
              primaryEnabled: _isConfirmButtonEnabled,
              onPrimaryPressed: () {
                context.push(
                  Uri(
                    path: AppRoutes.myPetHealthForm,
                    queryParameters: {
                      'petType': widget.petType,
                      'name': widget.name,
                      'breed': widget.breed,
                      'breedId': widget.breedId,
                      'profileImagePath': widget.profileImagePath,
                      'age': _selectedAge.toString(),
                      'dateBecameFamily': _selectedDate?.toApiDate(),
                      'gender': _selectedGender,
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
