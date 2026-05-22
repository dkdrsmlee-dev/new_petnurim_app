import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../core/widgets/social_login_button.dart';
import 'application/auth_providers.dart';
import 'domain/login_config.dart';
import 'domain/readable_auth_error.dart';
import 'domain/social_login_result.dart';
import 'domain/social_provider.dart';
import '../signup/application/signup_providers.dart';

class AuthStartScreen extends ConsumerStatefulWidget {
  const AuthStartScreen({super.key});

  @override
  ConsumerState<AuthStartScreen> createState() => _AuthStartScreenState();
}

class _AuthStartScreenState extends ConsumerState<AuthStartScreen> {
  SocialProvider? _pendingProvider;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final loginConfig = ref.watch(loginConfigProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('서비스 시작하기'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              '펫누림',
              style: textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '계정으로 바로 시작하세요',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '사용 가능한 로그인 수단을 확인한 뒤 안전하게 계정을 연결합니다.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            loginConfig.when(
              loading: () => const _AuthLoadingView(),
              error: (error, stackTrace) => _AuthConfigErrorView(
                message: _readErrorMessage(
                  error,
                  '로그인 설정을 불러오지 못했습니다. 다시 시도해 주세요.',
                ),
                onRetry: () => ref.invalidate(loginConfigProvider),
              ),
              data: (config) => _AuthProviderButtons(
                config: config,
                pendingProvider: _pendingProvider,
                errorMessage: _errorMessage,
                onSelectProvider: _startSocialLogin,
                onDebugSignup: _startDebugSignup,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startSocialLogin(
    SocialProvider provider,
    LoginConfig config,
  ) async {
    if (_pendingProvider != null || !config.isProviderEnabled(provider)) {
      return;
    }

    setState(() {
      _pendingProvider = provider;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(authRepositoryProvider)
          .loginWithProvider(provider);
      ref.read(pendingSocialLoginResultProvider.notifier).setResult(result);

      if (!mounted) {
        return;
      }

      switch (result.nextStep) {
        case SocialLoginNextStep.home:
          ref.read(signupFlowProvider.notifier).clear();
          context.go(AppRoutes.home);
          break;
        case SocialLoginNextStep.signup:
          ref.read(signupFlowProvider.notifier).startFromSocialLogin(result);
          context.go(AppRoutes.signupTerms);
          break;
      }
    } catch (error) {
      debugPrint(
        '[auth][${provider.name}] 로그인 실패: ${error.runtimeType}: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _readErrorMessage(
          error,
          '${provider.label} 로그인 연결에 실패했습니다. 다시 시도해 주세요.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _pendingProvider = null;
        });
      }
    }
  }

  void _startDebugSignup() {
    const mockProfile = SocialLoginProfile(
      provider: SocialProvider.kakao,
      providerLabel: '카카오',
      name: '홍길동',
      phone: '010-1234-1234',
    );
    final mockResult = SocialLoginResult(
      provider: SocialProvider.kakao,
      nextStep: SocialLoginNextStep.signup,
      accessToken: null,
      signupToken: 'mock_signup_token_for_debug_testing',
      profile: mockProfile,
    );
    ref.read(pendingSocialLoginResultProvider.notifier).setResult(mockResult);
    ref.read(signupFlowProvider.notifier).startFromSocialLogin(mockResult);
    context.go(AppRoutes.signupTerms);
  }

  String _readErrorMessage(Object error, String fallbackMessage) =>
      readAuthErrorMessage(error, fallbackMessage);
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AuthConfigErrorView extends StatelessWidget {
  const _AuthConfigErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            border: Border.all(color: const Color(0xFFFED7AA)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9A3412)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('다시 시도'),
        ),
      ],
    );
  }
}

class _AuthProviderButtons extends StatelessWidget {
  const _AuthProviderButtons({
    required this.config,
    required this.pendingProvider,
    required this.errorMessage,
    required this.onSelectProvider,
    required this.onDebugSignup,
  });

  final LoginConfig config;
  final SocialProvider? pendingProvider;
  final String? errorMessage;
  final void Function(SocialProvider provider, LoginConfig config)
  onSelectProvider;
  final VoidCallback onDebugSignup;

  @override
  Widget build(BuildContext context) {
    final hasAnyProvider = SocialProvider.values.any(config.isProviderEnabled);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final provider in SocialProvider.values) ...[
          SocialLoginButton(
            provider: provider,
            enabled:
                config.isProviderEnabled(provider) && pendingProvider == null,
            pending: pendingProvider == provider,
            onPressed: () => onSelectProvider(provider, config),
          ),
          const SizedBox(height: 12),
        ],
        if (!hasAnyProvider)
          const _AuthNotice(message: '현재 사용할 수 있는 SNS 로그인 수단이 없습니다.'),
        if (errorMessage != null && errorMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _AuthNotice(message: errorMessage!),
        ],
        if (kDebugMode) ...[
          OutlinedButton.icon(
            onPressed: pendingProvider == null ? onDebugSignup : null,
            icon: const Icon(Icons.bug_report_outlined, color: Colors.orange),
            label: const Text(
              '[테스트] 신규 가입 흐름 강제진입',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        ],
      ],
    );
  }
}



class _AuthNotice extends StatelessWidget {
  const _AuthNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: Text(message)),
    );
  }
}


