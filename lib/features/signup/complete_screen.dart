import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../auth/domain/readable_auth_error.dart';
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
      appBar: AppBar(title: const Text('가입 완료')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              '${profile.name.trim().isEmpty ? '회원' : profile.name}님, 환영합니다',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text('마지막으로 가입 완료 API를 호출한 뒤 홈으로 이동합니다.'),
            const SizedBox(height: 24),
            _ProfileSummary(profile: profile),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _CompleteNotice(message: _errorMessage!),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _completeSignup,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.home_outlined),
              label: Text(_saving ? '가입 완료 처리 중' : '서비스 시작하기'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _saving
                  ? null
                  : () => context.go(AppRoutes.signupProfile),
              icon: const Icon(Icons.arrow_back),
              label: const Text('회원정보 입력으로'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeSignup() async {
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
      await ref
          .read(signupRepositoryProvider)
          .completeSignup(signupToken: signupToken);
      ref.read(signupFlowProvider.notifier).clear();

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _readErrorMessage(error, '회원가입 완료 처리에 실패했습니다.');
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

  String _readErrorMessage(Object error, String fallbackMessage) =>
      readAuthErrorMessage(error, fallbackMessage);
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final SignupProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('이름', profile.name),
      ('연결 계정', profile.providerLabel),
      ('휴대폰번호', profile.phone),
      ('주소', profile.address1),
      ('생년월일', profile.birthDate),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        item.$1,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    Expanded(
                      child: Text(item.$2.trim().isEmpty ? '-' : item.$2),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
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
      child: Padding(padding: const EdgeInsets.all(14), child: Text(message)),
    );
  }
}
