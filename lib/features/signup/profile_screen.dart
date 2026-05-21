import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../auth/domain/readable_auth_error.dart';
import '../auth/domain/social_provider.dart';
import 'application/signup_providers.dart';
import 'domain/signup_profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profile = ref.read(signupFlowProvider).profile;
        _zipCodeController.text = profile.zipCode;
        _address1Controller.text = profile.address1;
        _address2Controller.text = profile.address2;
        _birthDateController.text = profile.birthDate;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _zipCodeController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _address1Controller.text.trim().isNotEmpty &&
        _address2Controller.text.trim().isNotEmpty &&
        _birthDateController.text.trim().isNotEmpty;
  }

  Future<void> _searchAddress() async {
    final result = await context.push<Map<String, String>>(AppRoutes.addressWebView);
    if (result != null && mounted) {
      setState(() {
        _zipCodeController.text = result['zonecode'] ?? '';
        _address1Controller.text = result['address'] ?? '';
      });
    }
  }

  void _selectBirthDate() {
    DateTime initialDate = DateTime(2000, 1, 1);
    if (_birthDateController.text.isNotEmpty) {
      try {
        final parts = _birthDateController.text.split('-');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        DateTime tempDate = initialDate;
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '생년월일',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setState(() {
                          final year = tempDate.year.toString();
                          final month = tempDate.month.toString().padLeft(2, '0');
                          final day = tempDate.day.toString().padLeft(2, '0');
                          _birthDateController.text = '$year-$month-$day';
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.light,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumYear: 1900,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitProfile() async {
    final signupToken = ref.read(signupFlowProvider).signupToken;
    if (signupToken == null || signupToken.trim().isEmpty) {
      setState(() {
        _errorMessage = '회원가입 토큰이 없어 회원정보를 저장할 수 없습니다. 소셜 로그인을 다시 시도해 주세요.';
      });
      return;
    }

    final currentProfile = ref.read(signupFlowProvider).profile;
    final nextProfile = currentProfile.copyWith(
      zipCode: _zipCodeController.text.trim(),
      address1: _address1Controller.text.trim(),
      address2: _address2Controller.text.trim(),
      birthDate: _birthDateController.text.trim(),
    );
    final validationMessage = _validateProfile(nextProfile);
    if (validationMessage != null) {
      setState(() {
        _errorMessage = validationMessage;
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      if (signupToken != 'mock_signup_token_for_debug_testing') {
        await ref
            .read(signupRepositoryProvider)
            .submitProfile(signupToken: signupToken, profile: nextProfile);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      ref.read(signupFlowProvider.notifier).updateProfile(nextProfile);

      if (mounted) {
        context.go(AppRoutes.signupComplete);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _readErrorMessage(error, '회원정보 저장에 실패했습니다.');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String? _validateProfile(SignupProfileDraft profile) {
    if (profile.zipCode.trim().isEmpty) {
      return '우편번호를 입력해 주세요.';
    }
    if (profile.address1.trim().isEmpty) {
      return '기본 주소를 입력해 주세요.';
    }
    if (profile.address2.trim().isEmpty) {
      return '상세 주소를 입력해 주세요.';
    }
    if (!_isValidBirthDate(profile.birthDate)) {
      return '생년월일은 YYYY-MM-DD 형식으로 입력해 주세요.';
    }

    return null;
  }

  bool _isValidBirthDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return false;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);

    return date.year == year && date.month == month && date.day == day;
  }

  String _readErrorMessage(Object error, String fallbackMessage) =>
      readAuthErrorMessage(error, fallbackMessage);

  String _formatBirthDate(String yyyymmdd) {
    if (yyyymmdd.isEmpty) return '';
    try {
      final parts = yyyymmdd.trim().split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return '$year년 $month월 $day일';
      }
    } catch (_) {}
    return yyyymmdd;
  }

  Widget _buildRowInfo(String label, String value, {SocialProvider? socialProvider}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              if (socialProvider != null) ...[
                _buildSocialLogoIcon(socialProvider),
                const SizedBox(width: 6),
              ],
              Text(
                value.trim().isEmpty ? '-' : value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogoIcon(SocialProvider provider) {
    if (provider == SocialProvider.kakao) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Color(0xFFFEE500),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'K',
            style: TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    } else if (provider == SocialProvider.naver) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: Color(0xFF03C75A),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'N',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final signupState = ref.watch(signupFlowProvider);
      final profile = signupState.profile;
      final formValid = _isFormValid();

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: _saving ? null : () => context.go(AppRoutes.signupVerify),
          ),
          title: const Text(
            '회원정보 입력',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  children: [
                    const Text(
                      '자동입력',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildRowInfo('이름', profile.name.trim().isEmpty ? '인증 회원' : profile.name),
                          const Divider(color: Color(0xFFE2E8F0)),
                          _buildRowInfo(
                            '연결계정',
                            profile.providerLabel.trim().isEmpty ? '소셜 계정' : profile.providerLabel,
                            socialProvider: profile.provider,
                          ),
                          const Divider(color: Color(0xFFE2E8F0)),
                          _buildRowInfo('휴대폰번호', profile.phone.trim().isEmpty ? '010-0000-0000' : profile.phone),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '추가 등록 정보(필수)',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '회원가입에 필요한 필수정보를 입력하신 후 회원가입을 완료해 주세요.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '주소',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _address1Controller,
                              readOnly: true,
                              onTap: _searchAddress,
                              style: const TextStyle(fontSize: 14, color: Colors.black),
                              decoration: const InputDecoration(
                                hintText: '주소 검색으로 주소를 입력해 주세요.',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: InputBorder.none,
                              ),
                              enabled: !_saving,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 96,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _saving ? null : _searchAddress,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                              fixedSize: const Size(96, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              '주소찾기',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _address2Controller,
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: '상세 주소를 입력해 주세요.',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: InputBorder.none,
                        ),
                        enabled: !_saving,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '생년월일',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _saving ? null : _selectBirthDate,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _birthDateController.text.isEmpty
                                  ? '생년월일을 선택해 주세요.'
                                  : _formatBirthDate(_birthDateController.text),
                              style: TextStyle(
                                color: _birthDateController.text.isEmpty
                                    ? const Color(0xFF94A3B8)
                                    : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      _ProfileNotice(message: _errorMessage!),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: formValid && !_saving ? _submitProfile : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '저장',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Text(
                '렌더링 에러가 발생했습니다:\n$e\n\n$stack',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }
  }
}

class _ProfileNotice extends StatelessWidget {
  const _ProfileNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: Text(message)),
    );
  }
}
