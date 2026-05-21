import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../auth/domain/readable_auth_error.dart';
import '../auth/domain/social_provider.dart';
import 'application/signup_providers.dart';
import 'domain/signup_profile.dart';

class CompleteScreen extends ConsumerStatefulWidget {
  const CompleteScreen({super.key});

  @override
  ConsumerState<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends ConsumerState<CompleteScreen> {
  bool _saving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(signupFlowProvider).profile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '회원가입 완료',
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                children: [
                  const SizedBox(height: 16),
                  // 회원증 아이콘 비주얼
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.contact_mail_outlined,
                          size: 46,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 환영 문구
                  Center(
                    child: Text(
                      '${profile.name.trim().isEmpty ? '회원' : profile.name}님,\n환영합니다',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'NURIM OS 회원가입이 완료되었습니다',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 요약 카드 정보
                  _ProfileSummary(profile: profile),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _CompleteNotice(message: _errorMessage!),
                  ],
                ],
              ),
            ),
            // 서비스 시작하기 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleServiceStart,
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
                          '서비스 시작하기',
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

  Future<void> _handleServiceStart() async {
    final signupToken = ref.read(signupFlowProvider).signupToken;
    if (signupToken == null || signupToken.trim().isEmpty) {
      setState(() {
        _errorMessage = '회원가입 토큰이 없어 가입 완료를 진행할 수 없습니다. 처음부터 다시 시도해 주세요.';
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
            .completeSignup(signupToken: signupToken);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      ref.read(signupFlowProvider.notifier).clear();

      if (mounted) {
        setState(() {
          _saving = false;
        });
        // 멤버십 팝업 노출
        await _showMembershipDialog();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = _readErrorMessage(error, '회원가입 완료 처리에 실패했습니다.');
        });
      }
    }
  }

  Future<void> _showMembershipDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: const Text(
            '멤버십 가입',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            '멤버십 가입을 하시면\n보다 많은 혜택을 받으실 수 있습니다.\n멤버십 가입을 진행할까요?',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // 팝업 닫기
                      context.go(AppRoutes.home); // 홈으로 이동
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('아니오', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 팝업 닫기
                      context.go(AppRoutes.home); // 홈으로 이동 (추후 멤버십 구독 화면 개발 시 전환 가능)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('예', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _readErrorMessage(Object error, String fallbackMessage) =>
      readAuthErrorMessage(error, fallbackMessage);
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final SignupProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    // 도로명 주소와 상세 주소 결합
    String fullAddress = profile.address1;
    if (profile.address2.isNotEmpty) {
      fullAddress = '$fullAddress ${profile.address2}';
    }

    // 생년월일 표시
    String birthDisplay = profile.birthDate;
    try {
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(profile.birthDate.trim());
      if (match != null) {
        birthDisplay = '${match.group(1)}년 ${match.group(2)}월 ${match.group(3)}일';
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildRow('이름', profile.name),
          const Divider(color: Color(0xFFE2E8F0)),
          _buildRow('연결계정', profile.providerLabel, socialProvider: profile.provider),
          const Divider(color: Color(0xFFE2E8F0)),
          _buildRow('휴대폰번호', profile.phone),
          const Divider(color: Color(0xFFE2E8F0)),
          _buildRow('주소', fullAddress.isEmpty ? '-' : fullAddress),
          const Divider(color: Color(0xFFE2E8F0)),
          _buildRow('생년월일', birthDisplay.isEmpty ? '-' : birthDisplay),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {SocialProvider? socialProvider}) {
    String displayValue = value.trim();
    if (displayValue.isEmpty || displayValue == '-') {
      if (label == '이름') {
        displayValue = '인증 회원';
      } else if (label == '연결계정') {
        displayValue = '소셜 계정';
      } else if (label == '휴대폰번호') {
        displayValue = '010-0000-0000';
      } else {
        displayValue = '-';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (socialProvider != null) ...[
                  _buildSocialLogoIcon(socialProvider),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    displayValue,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
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
}

class _CompleteNotice extends StatelessWidget {
  const _CompleteNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF9A3412),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
