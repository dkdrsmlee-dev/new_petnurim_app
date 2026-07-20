import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../core/storage/last_login_storage.dart';
import '../../core/widgets/last_login_badge.dart';
import '../../core/widgets/social_login_button.dart';
import 'application/auth_providers.dart';
import 'domain/login_config.dart';
import 'domain/readable_auth_error.dart';
import 'domain/social_login_result.dart';
import 'domain/social_provider.dart';
import '../signup/application/signup_providers.dart';
import '../../core/theme/app_colors.dart';

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
    final lastLoginAsync = ref.watch(lastLoginProviderProvider);
    final lastLoginProvider = lastLoginAsync.value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: loginConfig.when(
            loading: () => const _AuthLoadingView(),
            error: (error, stackTrace) => Center(
              child: _AuthConfigErrorView(
                message: _readErrorMessage(
                  error,
                  '로그인 설정을 불러오지 못했습니다. 다시 시도해 주세요.',
                ),
                onRetry: () => ref.invalidate(loginConfigProvider),
              ),
            ),
            data: (config) => Column(
              children: [
                const Spacer(flex: 3),
                const Text(
                  '안녕하세요 :)\n회원가입 후 이용해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 60),
                _AuthProviderButtons(
                  config: config,
                  pendingProvider: _pendingProvider,
                  errorMessage: _errorMessage,
                  lastLoginProvider: lastLoginProvider,
                  onSelectProvider: _startSocialLogin,
                ),
                const Spacer(flex: 4),
                if (kDebugMode) ...[
                  OutlinedButton.icon(
                    onPressed:
                        _pendingProvider == null ? _startDebugSignup : null,
                    icon: const Icon(
                      Icons.bug_report_outlined,
                      color: Colors.orange,
                    ),
                    label: const Text(
                      '[테스트] 신규 가입 흐름 강제진입',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
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

      // 로그인 성공 시 마지막 로그인 provider를 저장합니다.
      await ref
          .read(lastLoginStorageProvider)
          .saveLastLoginProvider(provider.name);

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
    required this.lastLoginProvider,
    required this.onSelectProvider,
  });

  final LoginConfig config;
  final SocialProvider? pendingProvider;
  final String? errorMessage;
  final SocialProvider? lastLoginProvider;
  final void Function(SocialProvider provider, LoginConfig config)
  onSelectProvider;

  @override
  Widget build(BuildContext context) {
    final hasAnyProvider = SocialProvider.values.any(config.isProviderEnabled);
    final providers = SocialProvider.values;
    final lastLoginIndex = lastLoginProvider != null
        ? providers.indexOf(lastLoginProvider!)
        : -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < providers.length; i++) ...[
                  SocialLoginButton(
                    provider: providers[i],
                    enabled:
                        config.isProviderEnabled(providers[i]) &&
                        pendingProvider == null,
                    pending: pendingProvider == providers[i],
                    onPressed: () => onSelectProvider(providers[i], config),
                  ),
                  if (i < providers.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
            if (lastLoginIndex != -1)
              Positioned(
                // 54(버튼 높이) + 12(간격)
                top: (lastLoginIndex * 66.0) + 54.0,
                left: 0,
                right: 0,
                child: const Align(
                  alignment: Alignment.center,
                  child: LastLoginBadge(),
                ),
              ),
          ],
        ),
        if (!hasAnyProvider)
          const _AuthNotice(message: '현재 사용할 수 있는 SNS 로그인 수단이 없습니다.'),
        if (errorMessage != null && errorMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _AuthNotice(message: errorMessage!),
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
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: Text(message)),
    );
  }
}


