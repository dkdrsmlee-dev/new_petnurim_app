import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_bootstrap.dart';
import '../../app/app_routes.dart';
import '../auth/domain/readable_auth_error.dart';
import 'application/signup_providers.dart';

class CompleteScreen extends ConsumerStatefulWidget {
  const CompleteScreen({super.key});

  @override
  ConsumerState<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends ConsumerState<CompleteScreen> {
  bool _saving = false;
  String? _errorMessage;

  Future<void> _finishSignup(String targetRoute) async {
    final signupToken = ref.read(signupFlowProvider).signupToken;
    if (signupToken == null || signupToken.trim().isEmpty) {
      ref.read(signupFlowProvider.notifier).clear();
      ref.invalidate(appBootstrapStateProvider);
      if (mounted) {
        context.go(targetRoute);
      }
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
      ref.invalidate(appBootstrapStateProvider);

      if (mounted) {
        setState(() {
          _saving = false;
        });
        context.go(targetRoute);
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

  String _readErrorMessage(Object error, String fallbackMessage) =>
      readAuthErrorMessage(error, fallbackMessage);

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF30343C), size: 24),
              onPressed: _saving ? null : () => _finishSignup(AppRoutes.home),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 190,
                      height: 190,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFD),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/img_signup_complete_cat.png',
                          width: 134,
                          height: 146,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '회원가입이 완료되었어요!',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF30343C),
                        height: 1.4,
                        letterSpacing: -0.66,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '마이펫 등록 후 멤버십에 가입하면\n더 다양한 혜택을 받을 수 있어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF87909E),
                        height: 1.4,
                        letterSpacing: -0.66,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _CompleteNotice(message: _errorMessage!),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => _finishSignup(AppRoutes.myPetAdd),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7F4FFF),
                            side: const BorderSide(color: Color(0xFF7F4FFF)),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '마이펫 등록',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.66,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saving ? null : () => _finishSignup(AppRoutes.home),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7F4FFF),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE8EBF1),
                            disabledForegroundColor: const Color(0xFFA2ADBE),
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
                                  '홈으로',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
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
