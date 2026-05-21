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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: _submitting ? null : () => context.go(AppRoutes.authStart),
        ),
        title: const Text(
          '서비스 약관동의',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: termsState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
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

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              const Text(
                '환영합니다!\n웹 3.0 서비스 이용약관에\n동의해 주세요.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              // 전체 동의 카드 (배경 박스)
              GestureDetector(
                onTap: terms.isEmpty || _submitting ? null : () => _toggleAll(!allChecked),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        allChecked ? Icons.check_circle : Icons.check_circle_outline,
                        color: allChecked ? Colors.black : const Color(0xFFCBD5E1),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '모두 확인 하였으며, 동의합니다.',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (terms.isEmpty)
                const _NoticeBox(message: '활성화된 약관이 없습니다.')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: terms.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final term = terms[index];
                    return _TermTile(
                      term: term,
                      checked: _isChecked(term),
                      enabled: !_submitting,
                      onChanged: (_) => _toggleTerm(term.termsId),
                      onOpen: () => _openTerm(term),
                    );
                  },
                ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _NoticeBox(message: _errorMessage!),
              ],
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  '만 14세 이상 회원 가입 가능합니다.\n해당 내용은 이용약관 및 정책에서도 확인 가능합니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // 하단 고정 버튼
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: requiredChecked && !_submitting
                  ? () => _submitTerms(terms)
                  : null,
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
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '본인 인증 후 가입하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isChecked(ActiveTerm term) => _checkedTerms[term.termsId] == true;

  bool _requiredTermsChecked(List<ActiveTerm> terms) {
    final requiredTerms = terms.where((term) => term.isRequired).toList();
    return terms.isNotEmpty && requiredTerms.every(_isChecked);
  }

  void _toggleAll(bool checked) {
    final terms = ref.read(activeTermsProvider).value ?? const <ActiveTerm>[];
    setState(() {
      for (final term in terms) {
        _checkedTerms[term.termsId] = checked;
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

      if (signupToken == 'mock_signup_token_for_debug_testing') {
        // 디버그 강제 진입 토큰인 경우 백엔드 API 통신을 모킹하여 통과 처리
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } else {
        await ref
            .read(signupRepositoryProvider)
            .submitTerms(signupToken: signupToken, agreements: agreements);
      }

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: enabled ? () => onChanged(!checked) : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      checked ? Icons.check_box : Icons.check_box_outline_blank,
                      color: checked ? Colors.black : const Color(0xFFCBD5E1),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '[${term.requiredLabel}] ${term.termsName}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            term.contentSummary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onOpen,
            icon: const Icon(
              Icons.chevron_right,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            tooltip: '약관 보기',
          ),
          const SizedBox(width: 4),
        ],
      ),
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
