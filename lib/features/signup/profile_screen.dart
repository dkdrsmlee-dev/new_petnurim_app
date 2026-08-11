import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../app/app_routes.dart';
import '../auth/domain/readable_auth_error.dart';
import '../auth/domain/social_provider.dart';
import 'application/signup_providers.dart';
import 'domain/signup_profile.dart';
import '../../core/theme/app_colors.dart';

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
        // 백엔드 profile-init 이 생년월일을 내려주지 않으므로 사용자가 직접 입력한다.
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
    // 생년월일은 본인인증 값이 자동 채워지는 읽기전용이므로 주소만 검증한다.
    return _address1Controller.text.trim().isNotEmpty &&
        _address2Controller.text.trim().isNotEmpty;
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
    if (profile.birthDate.trim().isNotEmpty && !_isValidBirthDate(profile.birthDate)) {
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

  @override
  Widget build(BuildContext context) {
    try {
      final signupState = ref.watch(signupFlowProvider);
      final profile = signupState.profile;
      final formValid = _isFormValid();

      // 연결계정: 실제 계정 이메일은 회원가입 단계(profile-init)에서 제공되지 않으므로
      // 가짜 이메일을 만들지 않고 연결된 소셜 계정(provider)만 표기한다.
      final providerName = profile.providerLabel.isNotEmpty
          ? profile.providerLabel
          : (profile.provider == SocialProvider.kakao ? '카카오' : '네이버');
      final connectedText = '$providerName 계정';

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: _saving ? null : () => context.go(AppRoutes.signupTerms),
          ),
          title: const Text(
            '회원 정보 입력',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.54,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    const Text(
                      '추가 정보를 입력하고\n회원가입을 완료해 주세요.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        color: AppColors.textStrong,
                        letterSpacing: -0.66,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 연결계정
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '연결계정',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: -0.66,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 52,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.bgGray,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              connectedText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDisabled,
                                letterSpacing: -0.66,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 생년월일
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '생년월일',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: -0.66,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 생년월일: 본인인증(KCP) 결과가 자동 채워지는 읽기전용 필드
                        Container(
                          height: 52,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.bgGray,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _birthDateController.text.replaceAll('-', '.'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDisabled,
                                letterSpacing: -0.66,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 주소
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '주소',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            letterSpacing: -0.66,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _saving ? null : _searchAddress,
                          child: Container(
                            height: 52,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _address1Controller.text.isEmpty
                                        ? '주소를 검색해 주세요.'
                                        : _address1Controller.text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _address1Controller.text.isEmpty
                                          ? AppColors.placeholder
                                          : AppColors.textStrong,
                                      letterSpacing: -0.66,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.search,
                                  size: 24,
                                  color: AppColors.textDisabled,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 52,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _address2Controller,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textStrong,
                            ),
                            decoration: const InputDecoration(
                              hintText: '상세주소를 입력해 주세요.',
                              hintStyle: TextStyle(
                                color: AppColors.placeholder,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            enabled: !_saving,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      _ProfileNotice(message: _errorMessage!),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: formValid && !_saving ? _submitProfile : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.borderLight,
                      disabledForegroundColor: AppColors.placeholder,
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
                            '다음',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.66,
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
