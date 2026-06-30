import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/nurim_date_picker.dart';
import '../../../core/widgets/page_header.dart';

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

  static const Color _primaryColor = Color(0xFF7F4FFF);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _textStrongColor = Color(0xFF30343C);
  static const Color _placeholderColor = Color(0xFFA2ADBE);
  static const Color _buttonDisabledBgColor = Color(0xFFE8EBF1);

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_validateForm);
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
                          fontFamily: 'Pretendard',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.66,
                          color: _textStrongColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 중성화 필드 (필수)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '중성화',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF51565F),
                                letterSpacing: -0.66,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3D3D),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
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
                                      color: _selectedNeutered == true ? _primaryColor : _borderColor,
                                      width: _selectedNeutered == true ? 1.5 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '했어요',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: _selectedNeutered == true ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedNeutered == true ? _primaryColor : _placeholderColor,
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
                                      color: _selectedNeutered == false ? _primaryColor : _borderColor,
                                      width: _selectedNeutered == false ? 1.5 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '안했어요',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: _selectedNeutered == false ? FontWeight.w600 : FontWeight.w500,
                                      color: _selectedNeutered == false ? _primaryColor : _placeholderColor,
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
                        Row(
                          children: [
                            const Text(
                              '체중',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF51565F),
                                letterSpacing: -0.66,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3D3D),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            color: _textStrongColor,
                          ),
                          decoration: InputDecoration(
                            hintText: '체중을 입력해 주세요.(ex 3.5)',
                            hintStyle: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              color: _placeholderColor,
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
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _textStrongColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _primaryColor, width: 1.5),
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
                        const Text(
                          '체중 측정일',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF51565F),
                            letterSpacing: -0.66,
                          ),
                        ),
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
                                    _selectedWeightDate != null
                                        ? '${_selectedWeightDate!.year}년 ${_selectedWeightDate!.month.toString().padLeft(2, '0')}월 ${_selectedWeightDate!.day.toString().padLeft(2, '0')}일'
                                        : '측정일을 선택해 주세요.',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      color: _selectedWeightDate != null ? _textStrongColor : _placeholderColor,
                                      letterSpacing: -0.66,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF909AA9),
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
                                color: _isPrimary ? _primaryColor : _borderColor,
                                width: 1.5,
                              ),
                              color: _isPrimary ? _primaryColor : Colors.white,
                            ),
                            child: _isPrimary
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '대표 펫으로 설정',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _textStrongColor,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // 취소 버튼
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showCancelDialog,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: _borderColor),
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF51565F),
                          letterSpacing: -0.66,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 다음 버튼
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isConfirmButtonEnabled
                          ? () {
                              context.push(
                                Uri(
                                  path: AppRoutes.myPetAddComplete,
                                  queryParameters: {
                                    'petType': widget.petType,
                                    'name': widget.name,
                                    'breed': widget.breed,
                                    'breedId': widget.breedId,
                                    'profileImagePath': widget.profileImagePath,
                                    'age': widget.age.toString(),
                                    'dateBecameFamily': widget.dateBecameFamily,
                                    'gender': widget.gender,
                                    'neutered': _selectedNeutered.toString(),
                                    'weight': _weightController.text.trim(),
                                    'weightDate': _selectedWeightDate != null
                                        ? '${_selectedWeightDate!.year}-${_selectedWeightDate!.month.toString().padLeft(2, '0')}-${_selectedWeightDate!.day.toString().padLeft(2, '0')}'
                                        : null,
                                    'isPrimary': _isPrimary.toString(),
                                  },
                                ).toString(),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _buttonDisabledBgColor,
                        disabledForegroundColor: _placeholderColor,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Text(
                        '다음',
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
          ],
        ),
      ),
    );
  }
}
