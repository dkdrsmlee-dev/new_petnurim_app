import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../core/widgets/edge_button_dialog.dart';
import '../auth/domain/readable_auth_error.dart';
import '../auth/domain/social_provider.dart';
import 'application/signup_providers.dart';
import 'domain/identity_verification.dart';
import 'domain/signup_profile.dart';
import 'kcp_cert_webview_screen.dart';
import '../../core/theme/app_colors.dart';

/// 본인인증 단계.
///
/// 별도의 통신사 선택/약관 목업 화면 없이, 진입하면 곧바로 KCP 본인인증
/// WebView 로 이동한다(통신사 선택·PASS/문자 인증·약관 동의는 KCP 인증창이
/// 담당). 인증 완료 시 profile-init 으로 이름·휴대폰을 받아 완료 화면을 노출한다.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  bool _submitting = true; // 진입 즉시 인증 시작
  bool _verified = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 화면 진입 직후 바로 KCP 본인인증을 시작한다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startVerification());
  }

  /// 회원가입 중단 확인 팝업. "나가기" 선택 시에만 로그인 화면으로 이탈한다.
  void _confirmCancelSignup() {
    if (_submitting) return;
    showDialog(
      context: context,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '회원가입을 중단하시겠어요?',
        content: '지금 나가면\n회원가입이 진행되지 않아요.',
        cancelText: '나가기',
        confirmText: '계속 가입하기',
        onCancel: () {
          Navigator.of(dialogContext).pop(); // 팝업 닫기
          context.go(AppRoutes.authStart); // 회원가입 이탈
        },
        onConfirm: () {}, // 계속 가입: 팝업만 닫힘(EdgeButtonDialog가 자동 pop)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmCancelSignup();
      },
      child: _verified
          ? _buildVerifiedView(context)
          : _buildLauncherView(context),
    );
  }

  /// 인증 진행/대기/재시도 화면 (목업 폼 대체)
  Widget _buildLauncherView(BuildContext context) {
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
          '본인인증',
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
            onPressed: _submitting ? null : _confirmCancelSignup,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _submitting
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 20),
                      Text(
                        '본인인증을 준비하고 있어요...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage ?? '본인인증이 필요합니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _startVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '본인인증 시작하기',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _startVerification() async {
    final signupToken = ref.read(signupFlowProvider).signupToken;
    if (signupToken == null || signupToken.trim().isEmpty) {
      setState(() {
        _submitting = false;
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
        await Future<void>.delayed(const Duration(milliseconds: 800));
        profileInit = const SignupProfileInit(
          name: '홍길동',
          phoneNumber: '01012341234',
          birthDate: '1995-05-15',
          provider: SocialProvider.kakao,
        );
      } else {
        // 1) KCP 본인인증 거래 등록 → 인증창 URL 획득
        final reqResult = await repository.requestIdentityVerification(
          signupToken: signupToken,
          purposeCode: IdentityPurpose.signup,
        );

        // 2) KCP 본인인증 WebView 로 바로 이동. 콜백 URL 도달 시 true 반환
        if (!mounted) return;
        final verified = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => KcpCertWebViewScreen(webViewUrl: reqResult.webViewUrl),
          ),
        );

        // 사용자 취소/미완료 시 재시도 화면 노출
        if (verified != true) {
          if (mounted) {
            setState(() {
              _submitting = false;
              _errorMessage = '본인인증이 완료되지 않았어요. 다시 시도해 주세요.';
            });
          }
          return;
        }

        // 3) 서버에서 검증된 본인인증 결과(이름·휴대폰) 조회
        profileInit = await repository.fetchProfileInit(
          signupToken: signupToken,
        );
      }

      ref.read(signupFlowProvider.notifier)
        ..mergeProfileInit(profileInit)
        ..markVerificationComplete();

      if (mounted) {
        setState(() {
          _submitting = false;
          _verified = true; // 본인인증 완료 상태화면 노출
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = _readErrorMessage(error, '본인인증 처리에 실패했습니다.');
        });
      }
    }
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
          '본인인증',
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
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.check, color: Colors.white, size: 50),
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '다음',
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

  String _readErrorMessage(Object error, String fallbackMessage) =>
      readAuthErrorMessage(error, fallbackMessage);
}
