import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../auth/domain/readable_auth_error.dart';
import '../auth/domain/social_provider.dart';
import 'application/signup_providers.dart';
import 'domain/signup_profile.dart';
import '../../core/theme/app_colors.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  bool _submitting = false;
  String? _errorMessage;
  
  // 1. 선택된 통신사 (기본 SKT)
  String _selectedTelecom = 'SKT';
  
  // 2. 본인인증 통과 여부 (대기화면 모사를 위함)
  bool _verified = false;

  // 3. PASS 약관 동의 상태
  bool _termPrivacy = false;
  bool _termUniqueId = false;
  bool _termService = false;
  bool _termTelecom = false;

  bool get _allChecked => _termPrivacy && _termUniqueId && _termService && _termTelecom;

  void _toggleAll(bool checked) {
    setState(() {
      _termPrivacy = checked;
      _termUniqueId = checked;
      _termService = checked;
      _termTelecom = checked;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_verified) {
      return _buildVerifiedView(context);
    }
    return _buildVerificationForm(context);
  }

  // 본인인증 진행 화면
  Widget _buildVerificationForm(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: _submitting ? null : () => context.go(AppRoutes.signupTerms),
        ),
        title: const Text(
          '웹 3.0 본인인증',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 24),
            onPressed: () => context.go(AppRoutes.authStart),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  const Text(
                    '이용중이신 통신사를\n선택해주세요',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 통신사 2x2 Grid
                  _buildTelecomGrid(),
                  const SizedBox(height: 32),
                  // 전체 동의
                  GestureDetector(
                    onTap: _submitting ? null : () => _toggleAll(!_allChecked),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(color: AppColors.borderSubtle),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _allChecked ? Icons.check_circle : Icons.check_circle_outline,
                            color: _allChecked ? Colors.black : const Color(0xFFCBD5E1),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '전체 동의하기',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 개별 약관 동의 Grid (2x2)
                  _buildSubTermsGrid(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _InfoBox(message: _errorMessage!, warning: true),
                  ],
                ],
              ),
            ),
            // 하단 버튼들
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _allChecked && !_submitting ? _verifyPhone : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48), // PASS Red
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.borderSubtle,
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'PASS로 인증하기',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _allChecked && !_submitting ? _verifyPhone : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155), // Slate Grey
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.borderSubtle,
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '문자(SMS)로 인증하기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  // 본인인증 완료 상태화면
  Widget _buildVerifiedView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '웹 3.0 본인인증',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 로고 또는 완성 아이콘
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'rn',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        '본인인증 완료!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '서비스 이용에 필요한 회원 추가정보를\n등록하시면 회원가입이 완료됩니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.signupProfile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '본인인증 완료',
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
  }

  Widget _buildTelecomGrid() {
    final list = ['SKT', 'KT', 'LG U+', '알뜰폰'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final telecom = list[index];
        final isSelected = _selectedTelecom == telecom;
        return GestureDetector(
          onTap: _submitting
              ? null
              : () {
                  setState(() {
                    _selectedTelecom = telecom;
                  });
                },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? Colors.black : AppColors.borderSubtle,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                telecom,
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFF64748B),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubTermsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTermCheckbox(
                label: '개인정보이용동의',
                value: _termPrivacy,
                onChanged: (val) => setState(() => _termPrivacy = val ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTermCheckbox(
                label: '고유식별정보처리동의',
                value: _termUniqueId,
                onChanged: (val) => setState(() => _termUniqueId = val ?? false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTermCheckbox(
                label: '서비스이용약관동의',
                value: _termService,
                onChanged: (val) => setState(() => _termService = val ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTermCheckbox(
                label: '통신사이용약관동의',
                value: _termTelecom,
                onChanged: (val) => setState(() => _termTelecom = val ?? false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: _submitting ? null : () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_box : Icons.check_box_outline_blank,
            color: value ? Colors.black : const Color(0xFFCBD5E1),
            size: 20,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPhone() async {
    final signupToken = ref.read(signupFlowProvider).signupToken;
    if (signupToken == null || signupToken.trim().isEmpty) {
      setState(() {
        _errorMessage = '회원가입 토큰이 없어 본인인증을 진행할 수 없습니다. 소셜 로그인을 다시 시도해 주세요.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(signupRepositoryProvider);
      final SignupProfileInit profileInit;

      if (signupToken == 'mock_signup_token_for_debug_testing') {
        // 디버그 강제 진입 토큰인 경우 본인인증 API 동작을 모킹
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        profileInit = const SignupProfileInit(
          name: '홍길동',
          phoneNumber: '01012341234',
          provider: SocialProvider.kakao,
        );
      } else {
        await repository.verifyPhone(signupToken: signupToken);
        profileInit = await repository.fetchProfileInit(
          signupToken: signupToken,
        );
      }

      debugPrint('[verify_screen] fetchProfileInit raw success: name="${profileInit.name}", phone="${profileInit.phoneNumber}", provider="${profileInit.provider}"');

      ref.read(signupFlowProvider.notifier)
        ..mergeProfileInit(profileInit)
        ..markVerificationComplete();

      if (mounted) {
        setState(() {
          _verified = true; // 본인인증 완료 상태화면 노출
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _readErrorMessage(error, '휴대폰 인증 단계 처리에 실패했습니다.');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String _readErrorMessage(Object error, String fallbackMessage) =>
      readAuthErrorMessage(error, fallbackMessage);
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.message, this.warning = false});

  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
        border: Border.all(
          color: warning ? const Color(0xFFFCA5A5) : AppColors.borderSubtle,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: warning ? const Color(0xFF991B1B) : const Color(0xFF334155),
              ),
        ),
      ),
    );
  }
}
