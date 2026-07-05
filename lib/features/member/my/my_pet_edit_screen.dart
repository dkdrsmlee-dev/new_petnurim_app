import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_bootstrap.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/nurim_date_picker.dart';
import '../../../core/widgets/page_header.dart';
import '../data/file_repository.dart';
import '../data/pet_repository.dart';
import '../domain/pet_breed.dart';
import 'my_pet_detail_screen.dart';
import 'my_pet_list_screen.dart';

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

  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _primaryStrongColor = Color(0xFF7025FF);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _textStrongColor = Color(0xFF30343C);
  static const Color _textMutedColor = Color(0xFF51565F);
  static const Color _textSecondaryColor = Color(0xFF87909E);
  static const Color _placeholderColor = Color(0xFFA2ADBE);
  static const Color _bgGrayColor = Color(0xFFF4F6F8);
  static const Color _buttonDisabledBgColor = Color(0xFFE8EBF1);

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
          _profileFileId = pet.profileFileId;
          _selectedBreed = pet.breedNameKor;
          _selectedBreedId = int.tryParse(pet.petBreedId);
          _selectedAge = pet.petAge;

          if (pet.familyDt.isNotEmpty) {
            _selectedDate = DateTime.tryParse(pet.familyDt);
          }
          _selectedGender = pet.genderCode;
          _selectedNeutered = pet.neuteredYn == 'Y';
          _weightController.text = pet.weightKg > 0 ? pet.weightKg.toString() : '';
          if (pet.weightMeasureDt.isNotEmpty) {
            _selectedWeightDate = DateTime.tryParse(pet.weightMeasureDt);
          }
          _isPrimary = pet.representYn == 'Y';

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
          child: Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: 52,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DBE4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                ListTile(
                  leading: SvgPicture.asset(
                    'assets/images/ic_camera.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(_textMutedColor, BlendMode.srcIn),
                  ),
                  title: const Text(
                    '사진 촬영',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textMutedColor,
                      letterSpacing: -0.66,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: SvgPicture.asset(
                    'assets/images/ic_album.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(_textMutedColor, BlendMode.srcIn),
                  ),
                  title: const Text(
                    '앨범 선택',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textMutedColor,
                      letterSpacing: -0.66,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _profileImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 가져오지 못했습니다.')),
        );
      }
    }
  }

  Future<void> _navigateToBreedSelect() async {
    final selected = await context.push<PetBreed>(
      Uri(
        path: AppRoutes.myPetBreedSelect,
        queryParameters: {'petType': _petType ?? 'DOG'},
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '나이',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textStrongColor,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, size: 24, color: _textStrongColor),
                    ),
                  ],
                ),
              ),
              const Divider(color: _borderColor),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    final ageVal = index + 1;
                    final isSelected = _selectedAge == ageVal;
                    return ListTile(
                      title: Text(
                        '$ageVal살',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? _primaryColor : _textStrongColor,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: _primaryColor, size: 20)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedAge = ageVal;
                        });
                        _validateForm();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
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

      final familyDtStr = _selectedDate != null
          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
          : null;

      final weightDateStr = _selectedWeightDate != null
          ? '${_selectedWeightDate!.year}-${_selectedWeightDate!.month.toString().padLeft(2, '0')}-${_selectedWeightDate!.day.toString().padLeft(2, '0')}'
          : null;

      await ref.read(petRepositoryProvider).updateMyPet(
        myPetId: widget.myPetId,
        petTypeCode: _petType ?? 'DOG',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
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
    final token = ref.watch(accessTokenProvider);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
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
            style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: _textMutedColor),
          ),
        ),
      );
    }

    // Build image provider
    ImageProvider? imageProv;
    if (_profileImagePath != null) {
      imageProv = FileImage(File(_profileImagePath!));
    } else if (_profileFileId != null) {
      final imgUrl = ref.read(apiClientProvider).uri('/api/v1/files/$_profileFileId/download').toString();
      imageProv = NetworkImage(
        imgUrl,
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
      );
    }

    final familyDateText = _selectedDate != null
        ? '${_selectedDate!.year}. ${_selectedDate!.month.toString().padLeft(2, '0')}. ${_selectedDate!.day.toString().padLeft(2, '0')}'
        : '가족이 된 날을 선택해 주세요.';

    final weightDateText = _selectedWeightDate != null
        ? '${_selectedWeightDate!.year}. ${_selectedWeightDate!.month.toString().padLeft(2, '0')}. ${_selectedWeightDate!.day.toString().padLeft(2, '0')}.'
        : '체중 측정일을 선택해 주세요.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '마이 펫 관리',
        showDivider: false,
        onBackPressed: _showCancelDialog,
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
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _bgGrayColor,
                                  border: Border.all(color: _borderColor, width: 1),
                                  image: imageProv != null
                                      ? DecorationImage(image: imageProv, fit: BoxFit.cover)
                                      : null,
                                ),
                                child: imageProv == null
                                    ? const Icon(Icons.pets, color: _placeholderColor, size: 48)
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
                                    border: Border.all(color: _borderColor, width: 1),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.camera_alt_outlined, size: 18, color: _textMutedColor),
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
                      style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: _textStrongColor),
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
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedBreed ?? '품종을 선택해 주세요.',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  color: _selectedBreed != null ? _textStrongColor : _placeholderColor,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: _textSecondaryColor, size: 24),
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
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedAge != null ? '$_selectedAge살' : '나이를 선택해 주세요.',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  color: _selectedAge != null ? _textStrongColor : _placeholderColor,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: _textSecondaryColor, size: 24),
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
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                familyDateText,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  color: _selectedDate != null ? _textStrongColor : _placeholderColor,
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, color: _textSecondaryColor, size: 20),
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
                        _buildTabButton('남아', _selectedGender == 'MALE', () {
                          setState(() {
                            _selectedGender = 'MALE';
                            _validateForm();
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildTabButton('여아', _selectedGender == 'FEMALE', () {
                          setState(() {
                            _selectedGender = 'FEMALE';
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
                      style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: _textStrongColor),
                      decoration: _buildInputDecoration('체중을 입력해 주세요.').copyWith(
                        suffixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text(
                            'Kg',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _textMutedColor,
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
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                weightDateText,
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  color: _selectedWeightDate != null ? _textStrongColor : _placeholderColor,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: _textSecondaryColor, size: 24),
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
                            color: _isPrimary ? _primaryColor : _borderColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '대표 펫으로 설정',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _textStrongColor,
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
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _buttonDisabledBgColor,
                  disabledForegroundColor: _placeholderColor,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '확인',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
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

  Widget _buildLabelRow(String text, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textMutedColor,
            letterSpacing: -0.66,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 2),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(color: Color(0xFFFF3D3D), shape: BoxShape.circle),
          ),
        ],
      ],
    );
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? _primaryColor : _borderColor, width: isSelected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? _primaryStrongColor : _textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: _placeholderColor, letterSpacing: -0.66),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
    );
  }
}
