import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
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
        : '${provider.label}로 시작하기';

    return SizedBox(
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.background,
          foregroundColor: colors.foreground,
          disabledBackgroundColor: colors.background.withValues(alpha: 0.45),
          disabledForegroundColor: colors.foreground.withValues(alpha: 0.58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.zero,
        ),
        onPressed: enabled ? onPressed : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.66,
                ),
              ),
            ),
            Positioned(
              left: 16,
              child: pending
                  ? SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.foreground,
                      ),
                    )
                  : SizedBox.square(
                      dimension: 24,
                      child: CustomPaint(
                        painter: provider == SocialProvider.kakao
                            ? KakaoLogoPainter(color: colors.foreground)
                            : NaverLogoPainter(color: colors.foreground),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class KakaoLogoPainter extends CustomPainter {
  final Color color;
  const KakaoLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final scaleX = size.width / 20.0;
    final scaleY = size.height / 18.7634;

    path.moveTo(10.0028 * scaleX, 0 * scaleY);
    path.cubicTo(
      4.47902 * scaleX, 0 * scaleY,
      0 * scaleX, 3.47874 * scaleY,
      0 * scaleX, 7.76327 * scaleY,
    );
    path.cubicTo(
      0 * scaleX, 10.4307 * scaleY,
      1.73382 * scaleX, 12.7813 * scaleY,
      4.36788 * scaleX, 14.1817 * scaleY,
    );
    path.lineTo(3.25646 * scaleX, 18.2551 * scaleY);
    path.cubicTo(
      3.15643 * scaleX, 18.6163 * scaleY,
      3.56766 * scaleX, 18.8997 * scaleY,
      3.88441 * scaleX, 18.6941 * scaleY,
    );
    path.lineTo(8.74687 * scaleX, 15.4654 * scaleY);
    path.cubicTo(
      9.1581 * scaleX, 15.5043 * scaleY,
      9.57488 * scaleX, 15.5265 * scaleY,
      9.99722 * scaleX, 15.5265 * scaleY,
    );
    path.cubicTo(
      15.521 * scaleX, 15.5265 * scaleY,
      20 * scaleX, 12.0478 * scaleY,
      20 * scaleX, 7.76327 * scaleY,
    );
    path.cubicTo(
      20 * scaleX, 3.47874 * scaleY,
      15.5265 * scaleX, 0 * scaleY,
      10.0028 * scaleX, 0 * scaleY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NaverLogoPainter extends CustomPainter {
  final Color color;
  const NaverLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final scaleX = size.width / 16.1333;
    final scaleY = size.height / 16.0;

    path.moveTo(10.9467 * scaleX, 8.56 * scaleY);
    path.lineTo(4.96 * scaleX, 0 * scaleY);
    path.lineTo(0 * scaleX, 0 * scaleY);
    path.lineTo(0 * scaleX, 16.0 * scaleY);
    path.lineTo(5.2 * scaleX, 16.0 * scaleY);
    path.lineTo(5.2 * scaleX, 7.44 * scaleY);
    path.lineTo(11.1733 * scaleX, 16.0 * scaleY);
    path.lineTo(16.1333 * scaleX, 16.0 * scaleY);
    path.lineTo(16.1333 * scaleX, 0 * scaleY);
    path.lineTo(10.9467 * scaleX, 0 * scaleY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
