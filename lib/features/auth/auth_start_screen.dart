import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import 'application/auth_providers.dart';
import 'domain/auth_exception.dart';
import 'domain/login_config.dart';
import 'domain/social_login_result.dart';
import 'domain/social_provider.dart';

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
                onBackToSplash: () => context.go(AppRoutes.splash),
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
          context.go(AppRoutes.home);
          break;
        case SocialLoginNextStep.signup:
          context.go(AppRoutes.signupTerms);
          break;
      }
    } catch (error) {
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

  String _readErrorMessage(Object error, String fallbackMessage) {
    if (error is AuthException) {
      return error.message;
    }

    return fallbackMessage;
  }
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
    required this.onBackToSplash,
  });

  final LoginConfig config;
  final SocialProvider? pendingProvider;
  final String? errorMessage;
  final void Function(SocialProvider provider, LoginConfig config)
  onSelectProvider;
  final VoidCallback onBackToSplash;

  @override
  Widget build(BuildContext context) {
    final hasAnyProvider = SocialProvider.values.any(config.isProviderEnabled);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final provider in SocialProvider.values) ...[
          _SocialLoginButton(
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
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: pendingProvider == null ? onBackToSplash : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('처음으로'),
        ),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.provider,
    required this.enabled,
    required this.pending,
    required this.onPressed,
  });

  final SocialProvider provider;
  final bool enabled;
  final bool pending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = _SocialLoginButtonColors.fromProvider(provider);
    final label = pending
        ? '${provider.label} 연결 중'
        : '${provider.label}로 계속하기';

    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          disabledBackgroundColor: colors.background.withValues(alpha: 0.45),
          disabledForegroundColor: colors.foreground.withValues(alpha: 0.58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: enabled ? onPressed : null,
        icon: pending
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.foreground,
                ),
              )
            : Icon(
                provider == SocialProvider.kakao
                    ? Icons.chat_bubble_outline
                    : Icons.check_circle_outline,
              ),
        label: Text(label),
      ),
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

class _SocialLoginButtonColors {
  const _SocialLoginButtonColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;

  factory _SocialLoginButtonColors.fromProvider(SocialProvider provider) {
    switch (provider) {
      case SocialProvider.kakao:
        return const _SocialLoginButtonColors(
          background: Color(0xFFFEE500),
          foreground: Color(0xFF111827),
        );
      case SocialProvider.naver:
        return const _SocialLoginButtonColors(
          background: Color(0xFF03C75A),
          foreground: Colors.white,
        );
    }
  }
}
