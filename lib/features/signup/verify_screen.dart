import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../auth/domain/readable_auth_error.dart';
import 'application/signup_providers.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  bool _submitting = false;
  String? _errorMessage;
  String _telecom = 'SKT';

  static const _telecomOptions = ['SKT', 'KT', 'LG U+', '알뜰폰'];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(signupFlowProvider).profile;

    return Scaffold(
      appBar: AppBar(title: const Text('본인인증')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              '회원가입 2단계',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '휴대폰 인증을 진행합니다',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              '${profile.name.trim().isEmpty ? '회원' : profile.name}님의 실명과 휴대폰 정보를 확인합니다.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final telecom in _telecomOptions)
                  ChoiceChip(
                    label: Text(telecom),
                    selected: _telecom == telecom,
                    onSelected: _submitting
                        ? null
                        : (_) {
                            setState(() {
                              _telecom = telecom;
                            });
                          },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const _InfoBox(
              message:
                  '현재 단계는 서버의 휴대폰 인증 처리 API를 호출합니다. 제공사 웹 인증이 필요해지면 다음 단계에서 WebView로 분리합니다.',
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _InfoBox(message: _errorMessage!, warning: true),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _verifyPhone,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(_submitting ? '인증 처리 중' : '휴대폰 인증 진행하기'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _submitting
                  ? null
                  : () => context.go(AppRoutes.signupTerms),
              icon: const Icon(Icons.arrow_back),
              label: const Text('약관 동의로'),
            ),
          ],
        ),
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
      await repository.verifyPhone(signupToken: signupToken);
      final profileInit = await repository.fetchProfileInit(
        signupToken: signupToken,
      );
      ref.read(signupFlowProvider.notifier)
        ..mergeProfileInit(profileInit)
        ..markVerificationComplete();

      if (mounted) {
        context.go(AppRoutes.signupProfile);
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
        color: warning ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
        border: Border.all(
          color: warning ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: Text(message)),
    );
  }
}
