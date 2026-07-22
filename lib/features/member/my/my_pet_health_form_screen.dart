import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/nurim_date_picker.dart';
import '../../../core/widgets/page_header.dart';
import '../data/file_repository.dart';
import '../data/pet_repository.dart';
import 'my_pet_list_screen.dart';
import '../../../core/theme/app_colors.dart';

class MyPetHealthFormScreen extends ConsumerStatefulWidget {
  final String petType;
  final String name;
  final String? breed;
  final String? breedId;
  final String? profileImagePath;
  final int age;
  final String? dateBecameFamily;
  final String gender;

  const MyPetHealthFormScreen({
    super.key,
    required this.petType,
    required this.name,
    this.breed,
    this.breedId,
    this.profileImagePath,
    required this.age,
    this.dateBecameFamily,
    required this.gender,
  });

  @override
  ConsumerState<MyPetHealthFormScreen> createState() => _MyPetHealthFormScreenState();
}

class _MyPetHealthFormScreenState extends ConsumerState<MyPetHealthFormScreen> {
  bool? _selectedNeutered; // true: 했어요, false: 안했어요
  final TextEditingController _weightController = TextEditingController();
  DateTime? _selectedWeightDate; // 체중 측정일
  bool _isPrimary = false; // 대표 펫으로 설정
  bool _isConfirmButtonEnabled = false;
  bool _isSubmitting = false;


  @override
  void initState() {
    super.initState();
    _weightController.addListener(_validateForm);
    
    // Check if the current pet list is empty and default _isPrimary to true
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petsAsync = ref.read(myPetsListProvider);
      if (petsAsync.hasValue && petsAsync.value!.isEmpty) {
        setState(() {
          _isPrimary = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _weightController.removeListener(_validateForm);
    _weightController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isConfirmButtonEnabled = _selectedNeutered != null && _weightController.text.trim().isNotEmpty;
    });
  }

  // 체중 측정일 데이트 피커 바텀 시트 호출
  Future<void> _showWeightDatePicker() async {
    final selected = await NurimDatePickerBottomSheet.show(
      context: context,
      title: '체중 측정일',
      initialDate: _selectedWeightDate ?? DateTime.now(),
      maximumDate: DateTime.now(),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedWeightDate = selected;
      });
    }
  }

  Future<void> _submitMyPet() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      int? profileFileId;
      if (widget.profileImagePath != null && widget.profileImagePath!.isNotEmpty) {
        final file = File(widget.profileImagePath!);
        if (await file.exists()) {
          final fileBytes = await file.readAsBytes();
          final uploadResult = await ref.read(fileRepositoryProvider).uploadFile(
            fileBytes: fileBytes,
            filename: widget.profileImagePath!.split('/').last,
          );
          final rawFileId = uploadResult['fileId'];
          if (rawFileId != null) {
            profileFileId = int.tryParse(rawFileId.toString());
          }
        }
      }

      final breedIdVal = (widget.breedId != null && widget.breedId != 'null')
          ? int.tryParse(widget.breedId!)
          : null;

      final weightVal = double.tryParse(_weightController.text.trim()) ?? 0.0;

      final weightDateStr = _selectedWeightDate != null
          ? _selectedWeightDate!.toApiDate()
          : widget.dateBecameFamily!;

      // Check if it's the first pet to register
      final petsAsync = ref.read(myPetsListProvider);
      bool isFirstPet = false;
      if (petsAsync.hasValue) {
        isFirstPet = petsAsync.value!.isEmpty;
      } else {
        try {
          final response = await ref.read(petRepositoryProvider).getMyPetsList(limit: 1);
          isFirstPet = response.items.isEmpty;
        } catch (_) {
          isFirstPet = false;
        }
      }

      final representYnValue = (isFirstPet || _isPrimary) ? 'Y' : 'N';

      final response = await ref.read(petRepositoryProvider).createMyPet(
        petTypeCode: widget.petType,
        petName: widget.name,
        petBreedId: breedIdVal,
        petAge: widget.age,
        familyDt: widget.dateBecameFamily!,
        genderCode: widget.gender,
        neuteredYn: _selectedNeutered == true ? 'Y' : 'N',
        weightKg: weightVal,
        weightMeasureDt: weightDateStr,
        representYn: representYnValue,
        profileFileId: profileFileId,
      );

      if (mounted) {
        context.push(
          Uri(
            path: AppRoutes.myPetAddComplete,
            queryParameters: {
              'myPetId': response.myPetId,
            },
          ).toString(),
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.show(context, '마이펫 등록에 실패했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
                        '마지막이에요!\n건강 정보를 알려주세요.',
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
                    // 중성화 필드 (필수)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NurimFieldLabel('중성화', isRequired: true),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // 했어요 버튼
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedNeutered = true;
                                  });
                                  _validateForm();
                                },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedNeutered == true ? AppColors.primary : AppColors.border,
                                      width: _selectedNeutered == true ? 1.5 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '했어요',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: _selectedNeutered == true ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedNeutered == true ? AppColors.primary : AppColors.placeholder,
                                      letterSpacing: -0.66,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 안했어요 버튼
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedNeutered = false;
                                  });
                                  _validateForm();
                                },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedNeutered == false ? AppColors.primary : AppColors.border,
                                      width: _selectedNeutered == false ? 1.5 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '안했어요',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: _selectedNeutered == false ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedNeutered == false ? AppColors.primary : AppColors.placeholder,
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
                    const SizedBox(height: 24),
                    // 체중 필드 (필수)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NurimFieldLabel('체중', isRequired: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textStrong,
                          ),
                          decoration: InputDecoration(
                            hintText: '체중을 입력해 주세요.(ex 3.5)',
                            hintStyle: const TextStyle(
                              fontSize: 16,
                              color: AppColors.placeholder,
                              letterSpacing: -0.66,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Kg',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textStrong,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                    // 체중 측정일 필드 (선택)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NurimFieldLabel('체중 측정일'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showWeightDatePicker,
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
                                    _selectedWeightDate != null
                                        ? _selectedWeightDate!.toKoreanDate()
                                        : '측정일을 선택해 주세요.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedWeightDate != null ? AppColors.textStrong : AppColors.placeholder,
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
                    const SizedBox(height: 32),
                    // 대표 펫으로 설정 (원형 체크박스)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPrimary = !_isPrimary;
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isPrimary ? AppColors.primary : AppColors.border,
                                width: 1.5,
                              ),
                              color: _isPrimary ? AppColors.primary : Colors.white,
                            ),
                            child: _isPrimary
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '대표 펫으로 설정',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textStrong,
                              letterSpacing: -0.66,
                            ),
                          ),
                        ],
                      ),
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
              primaryEnabled: _isConfirmButtonEnabled,
              isLoading: _isSubmitting,
              onPrimaryPressed: _submitMyPet,
            ),
          ],
        ),
      ),
    );
  }
}
