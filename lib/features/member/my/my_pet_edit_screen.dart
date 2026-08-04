import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_routes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/authed_file_image.dart';
import '../../../core/widgets/age_picker_sheet.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/nurim_date_picker.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/photo_source_sheet.dart';
import '../data/file_repository.dart';
import '../data/pet_repository.dart';
import '../domain/pet_codes.dart';
import '../domain/pet_breed.dart';
import 'my_pet_detail_screen.dart';
import 'my_pet_list_screen.dart';
import '../../../core/theme/app_colors.dart';

class MyPetEditScreen extends ConsumerStatefulWidget {
  final String myPetId;

  const MyPetEditScreen({
    super.key,
    required this.myPetId,
  });

  @override
  ConsumerState<MyPetEditScreen> createState() => _MyPetEditScreenState();
}

class _MyPetEditScreenState extends ConsumerState<MyPetEditScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String? _petType; // 'DOG' or 'CAT'
  String? _profileImagePath; // Local picked path if modified
  int? _profileFileId; // Existing profile file ID
  String? _selectedBreed;
  int? _selectedBreedId;
  int? _selectedAge;
  DateTime? _selectedDate; // 가족이 된 날
  String? _selectedGender; // 'MALE' or 'FEMALE'
  bool? _selectedNeutered; // true: 했어요, false: 안했어요
  DateTime? _selectedWeightDate; // 체중 측정일
  bool _isPrimary = false; // 대표 펫으로 설정

  bool _isConfirmButtonEnabled = false;
  bool _isSubmitting = false;

  // 최초 로드값 스냅샷 (변경 감지 기준)
  String _initialName = '';
  int? _initialBreedId;
  int? _initialAge;
  DateTime? _initialDate;
  String? _initialGender;
  bool? _initialNeutered;
  String _initialWeight = '';
  DateTime? _initialWeightDate;
  bool _initialIsPrimary = false;


  @override
  void initState() {
    super.initState();
    _loadPetDetail();
    _nameController.addListener(_validateForm);
    _weightController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _weightController.removeListener(_validateForm);
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadPetDetail() async {
    try {
      final pet = await ref.read(petRepositoryProvider).getMyPetDetail(widget.myPetId);
      if (mounted) {
        setState(() {
          _petType = pet.petTypeCode;
          _nameController.text = pet.petName;
          _profileFileId = pet.profileFileId != null ? int.tryParse(pet.profileFileId!) : null;
          _selectedBreed = pet.breedNameKor;
          _selectedBreedId = int.tryParse(pet.petBreedId);
          _selectedAge = pet.petAge;

          if (pet.familyDt.isNotEmpty) {
            _selectedDate = DateTime.tryParse(pet.familyDt);
          }
          _selectedGender = pet.genderCode;
          _selectedNeutered = YesNo.isYes(pet.neuteredYn);
          _weightController.text = pet.weightKg > 0 ? pet.weightKg.toString() : '';
          if (pet.weightMeasureDt.isNotEmpty) {
            _selectedWeightDate = DateTime.tryParse(pet.weightMeasureDt);
          }
          _isPrimary = YesNo.isYes(pet.representYn);

          // 변경 감지 기준값 스냅샷 저장
          _initialName = _nameController.text.trim();
          _initialBreedId = _selectedBreedId;
          _initialAge = _selectedAge;
          _initialDate = _selectedDate;
          _initialGender = _selectedGender;
          _initialNeutered = _selectedNeutered;
          _initialWeight = _weightController.text.trim();
          _initialWeightDate = _selectedWeightDate;
          _initialIsPrimary = _isPrimary;

          _isLoading = false;
        });
        _validateForm();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '마이펫 정보를 불러오지 못했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  void _validateForm() {
    final name = _nameController.text.trim();
    final weight = _weightController.text.trim();
    setState(() {
      _isConfirmButtonEnabled = name.isNotEmpty &&
          _selectedAge != null &&
          _selectedGender != null &&
          _selectedNeutered != null &&
          weight.isNotEmpty;
    });
  }

  void _showPhotoBottomSheet() {
    showPhotoSourceSheet(
      context,
      onCamera: () => _pickImage(ImageSource.camera),
      onGallery: () => _pickImage(ImageSource.gallery),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final path = await pickImagePath(context, source);
    if (path != null) {
      setState(() {
        _profileImagePath = path;
      });
    }
  }

  Future<void> _navigateToBreedSelect() async {
    final selected = await context.push<PetBreed>(
      Uri(
        path: AppRoutes.myPetBreedSelect,
        queryParameters: {'petType': _petType ?? PetType.dog},
      ).toString(),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedBreed = selected.breedNameKor;
        _selectedBreedId = int.tryParse(selected.petBreedId);
        _validateForm();
      });
    }
  }

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

  Future<void> _savePetInfo() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      int? profileFileId = _profileFileId;
      if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
        final file = File(_profileImagePath!);
        if (await file.exists()) {
          final fileBytes = await file.readAsBytes();
          final uploadResult = await ref.read(fileRepositoryProvider).uploadFile(
            fileBytes: fileBytes,
            filename: _profileImagePath!.split('/').last,
          );
          final rawFileId = uploadResult['fileId'];
          if (rawFileId != null) {
            profileFileId = int.tryParse(rawFileId.toString());
          }
        }
      }

      final weightVal = double.tryParse(_weightController.text.trim()) ?? 0.0;

      final familyDtStr = _selectedDate?.toApiDate();

      final weightDateStr = _selectedWeightDate?.toApiDate();

      await ref.read(petRepositoryProvider).updateMyPet(
        myPetId: widget.myPetId,
        petTypeCode: _petType ?? PetType.dog,
        petName: _nameController.text.trim(),
        petAge: _selectedAge!,
        genderCode: _selectedGender!,
        neuteredYn: _selectedNeutered == true ? 'Y' : 'N',
        weightKg: weightVal,
        representYn: _isPrimary ? 'Y' : 'N',
        petBreedId: _selectedBreedId,
        profileFileId: profileFileId,
        familyDt: familyDtStr,
        weightMeasureDt: weightDateStr,
      );

      // Invalidate provider so that details reflect the changes
      ref.invalidate(myPetDetailProvider(widget.myPetId));
      ref.invalidate(myPetsListProvider); // invalidate lists as well

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.show(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _hasChanges() {
    if (_profileImagePath != null) return true; // 사진 새로 선택
    if (_nameController.text.trim() != _initialName) return true;
    if (_selectedBreedId != _initialBreedId) return true;
    if (_selectedAge != _initialAge) return true;
    if (_selectedDate != _initialDate) return true;
    if (_selectedGender != _initialGender) return true;
    if (_selectedNeutered != _initialNeutered) return true;
    if (_weightController.text.trim() != _initialWeight) return true;
    if (_selectedWeightDate != _initialWeightDate) return true;
    if (_isPrimary != _initialIsPrimary) return true;
    return false;
  }

  void _handleBackPressed() {
    if (_hasChanges()) {
      _showCancelDialog();
    } else {
      context.pop();
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return EdgeButtonDialog(
          title: '수정을 중단하시겠어요?',
          content: '지금까지 입력한 정보는\n저장되지 않아요.',
          cancelText: '취소',
          confirmText: '확인',
          onConfirm: () {
            context.pop(); // dismiss dialog
            context.pop(); // pop edit screen
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: NurimPageHeader(
          title: '마이 펫 관리',
          onBackPressed: () => context.pop(),
        ),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
        ),
      );
    }

    // Build image provider
    ImageProvider? imageProv;
    if (_profileImagePath != null) {
      imageProv = FileImage(File(_profileImagePath!));
    } else if (_profileFileId != null) {
      imageProv = AuthedFileImageX.of(ref, _profileFileId!.toString(),
          variant: 'medium', downloadFallback: true);
    }

    final familyDateText = _selectedDate != null
        ? _selectedDate!.toDotDate()
        : '가족이 된 날을 선택해 주세요.';

    final weightDateText = _selectedWeightDate != null
        ? _selectedWeightDate!.toDotDate(trailing: true)
        : '체중 측정일을 선택해 주세요.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '마이 펫 관리',
        showDivider: false,
        onBackPressed: _handleBackPressed,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Profile Image Selector
                    Center(
                      child: GestureDetector(
                        onTap: _showPhotoBottomSheet,
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.bgGray,
                                  border: Border.all(color: AppColors.border, width: 1),
                                  image: imageProv != null
                                      ? DecorationImage(image: imageProv, fit: BoxFit.cover)
                                      : null,
                                ),
                                 child: imageProv == null
                                    ? Stack(
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
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border, width: 1),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 이름
                    _buildLabelRow('이름', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 16, color: AppColors.textStrong),
                      decoration: _buildInputDecoration('이름을 입력해 주세요.'),
                    ),
                    const SizedBox(height: 24),

                    // 품종
                    _buildLabelRow('품종'),
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
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 나이
                    _buildLabelRow('나이', isRequired: true),
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
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 가족이 된 날
                    _buildLabelRow('가족이 된 날'),
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
                                familyDateText,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDate != null ? AppColors.textStrong : AppColors.placeholder,
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 성별
                    _buildLabelRow('성별', isRequired: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTabButton('남아', _selectedGender == PetGender.male, () {
                          setState(() {
                            _selectedGender = PetGender.male;
                            _validateForm();
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildTabButton('여아', _selectedGender == PetGender.female, () {
                          setState(() {
                            _selectedGender = PetGender.female;
                            _validateForm();
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 중성화
                    _buildLabelRow('중성화', isRequired: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTabButton('했어요', _selectedNeutered == true, () {
                          setState(() {
                            _selectedNeutered = true;
                            _validateForm();
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildTabButton('안했어요', _selectedNeutered == false, () {
                          setState(() {
                            _selectedNeutered = false;
                            _validateForm();
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 체중
                    _buildLabelRow('체중', isRequired: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 16, color: AppColors.textStrong),
                      decoration: _buildInputDecoration('체중을 입력해 주세요.').copyWith(
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text(
                            'Kg',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 체중 측정일
                    _buildLabelRow('체중 측정일'),
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
                                weightDateText,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedWeightDate != null ? AppColors.textStrong : AppColors.placeholder,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 대표 펫 설정 Checkbox
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPrimary = !_isPrimary;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            _isPrimary ? Icons.check_circle : Icons.check_circle_outline,
                            color: _isPrimary ? AppColors.primary : AppColors.border,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '대표 펫으로 설정',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Bottom confirmation button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: (_isConfirmButtonEnabled && !_isSubmitting) ? _savePetInfo : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.borderLight,
                  disabledForegroundColor: AppColors.placeholder,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.66,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelRow(String text, {bool isRequired = false}) =>
      NurimFieldLabel(text, isRequired: isRequired);

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) =>
      Expanded(
        child: NurimSelectableTab(
          label: label,
          selected: isSelected,
          onTap: onTap,
        ),
      );

  InputDecoration _buildInputDecoration(String hint) =>
      nurimInputDecoration(hint);
}
