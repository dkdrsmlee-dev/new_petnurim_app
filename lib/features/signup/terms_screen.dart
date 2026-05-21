import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../auth/domain/readable_auth_error.dart';
import 'application/signup_providers.dart';
import 'domain/signup_terms.dart';

class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  final Map<String, bool> _checkedTerms = {};
  bool _submitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final termsState = ref.watch(activeTermsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('약관 동의')),
      body: SafeArea(
        child: termsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorView(
            message: _readErrorMessage(error, '약관 목록을 불러오지 못했습니다.'),
            onRetry: () => ref.invalidate(activeTermsProvider),
          ),
          data: _buildTerms,
        ),
      ),
    );
  }

  Widget _buildTerms(List<ActiveTerm> terms) {
    final requiredChecked = _requiredTermsChecked(terms);
    final allChecked = terms.isNotEmpty && terms.every(_isChecked);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        Text(
          '회원가입 1단계',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '약관을 확인해 주세요',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text('필수 약관에 동의하면 본인인증 단계로 이동할 수 있습니다.'),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: allChecked,
          onChanged: terms.isEmpty || _submitting ? null : _toggleAll,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('전체 동의'),
        ),
        const Divider(height: 24),
        if (terms.isEmpty)
          const _NoticeBox(message: '활성화된 약관이 없습니다.')
        else
          for (final term in terms)
            _TermTile(
              term: term,
              checked: _isChecked(term),
              enabled: !_submitting,
              onChanged: (_) => _toggleTerm(term.termsId),
              onOpen: () => _openTerm(term),
            ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          _NoticeBox(message: _errorMessage!),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: requiredChecked && !_submitting
              ? () => _submitTerms(terms)
              : null,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(_submitting ? '약관 저장 중' : '본인인증 진행하기'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _submitting ? null : () => context.go(AppRoutes.authStart),
          icon: const Icon(Icons.arrow_back),
          label: const Text('로그인 시작으로'),
        ),
      ],
    );
  }

  bool _isChecked(ActiveTerm term) => _checkedTerms[term.termsId] == true;

  bool _requiredTermsChecked(List<ActiveTerm> terms) {
    final requiredTerms = terms.where((term) => term.isRequired).toList();
    return terms.isNotEmpty && requiredTerms.every(_isChecked);
  }

  void _toggleAll(bool? checked) {
    final terms = ref.read(activeTermsProvider).value ?? const <ActiveTerm>[];
    setState(() {
      for (final term in terms) {
        _checkedTerms[term.termsId] = checked == true;
      }
    });
  }

  void _toggleTerm(String termsId) {
    setState(() {
      _checkedTerms[termsId] = !(_checkedTerms[termsId] ?? false);
    });
  }

  Future<void> _submitTerms(List<ActiveTerm> terms) async {
    final signupToken = ref.read(signupFlowProvider).signupToken;
    if (signupToken == null || signupToken.trim().isEmpty) {
      setState(() {
        _errorMessage = '회원가입 토큰이 없어 약관 동의를 저장할 수 없습니다. 소셜 로그인을 다시 시도해 주세요.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final agreements = terms
          .map(
            (term) =>
                TermAgreement(termsId: term.termsId, agreed: _isChecked(term)),
          )
          .toList();
      await ref
          .read(signupRepositoryProvider)
          .submitTerms(signupToken: signupToken, agreements: agreements);

      if (mounted) {
        context.go(AppRoutes.signupVerify);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _readErrorMessage(error, '약관 동의 저장에 실패했습니다.');
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

  void _openTerm(ActiveTerm term) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                '[${term.requiredLabel}] ${term.termsName}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Text(term.content.isEmpty ? '약관 본문이 비어 있습니다.' : term.content),
            ],
          ),
        );
      },
    );
  }

  String _readErrorMessage(Object error, String fallbackMessage) =>
      readAuthErrorMessage(error, fallbackMessage);
}

class _TermTile extends StatelessWidget {
  const _TermTile({
    required this.term,
    required this.checked,
    required this.enabled,
    required this.onChanged,
    required this.onOpen,
  });

  final ActiveTerm term;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(value: checked, onChanged: enabled ? onChanged : null),
      title: Text('[${term.requiredLabel}] ${term.termsName}'),
      subtitle: term.termsKey.isEmpty ? null : Text(term.termsKey),
      trailing: IconButton(
        onPressed: onOpen,
        icon: const Icon(Icons.chevron_right),
        tooltip: '약관 보기',
      ),
      onTap: enabled ? () => onChanged(!checked) : null,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _NoticeBox(message: message),
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

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.message});

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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9A3412)),
        ),
      ),
    );
  }
}
