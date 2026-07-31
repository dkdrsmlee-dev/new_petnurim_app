import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../core/widgets/bottom_action_bar.dart';
import '../../core/widgets/edge_button_dialog.dart';
import '../auth/domain/readable_auth_error.dart';
import 'application/signup_providers.dart';
import 'domain/signup_terms.dart';
import '../../core/theme/app_colors.dart';

class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  final Map<String, bool> _checkedTerms = {};
  bool _submitting = false;
  String? _errorMessage;

  /// 회원가입 중단 확인 팝업. "나가기" 선택 시에만 로그인 화면으로 이탈한다.
  void _confirmCancelSignup() {
    if (_submitting) return;
    showDialog(
      context: context,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '회원가입을 중단하시겠어요?',
        content: '약관 동의를 완료하지 않으면\n회원가입이 진행되지 않아요.',
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
    final termsState = ref.watch(activeTermsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmCancelSignup();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textStrong,
            size: 24,
          ),
          onPressed: _submitting ? null : _confirmCancelSignup,
        ),
        title: null,
        centerTitle: true,
      ),
      body: SafeArea(
        child: termsState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
          error: (error, stackTrace) => _ErrorView(
            message: _readErrorMessage(error, '약관 목록을 불러오지 못했습니다.'),
            onRetry: () => ref.invalidate(activeTermsProvider),
          ),
          data: _buildTerms,
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              const Text(
                '서비스 이용을 위해\n약관에 동의해 주세요.',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.66,
                ),
              ),
              const SizedBox(height: 40),
              // 전체 동의 카드 (배경 박스)
              GestureDetector(
                onTap: terms.isEmpty || _submitting
                    ? null
                    : () => _toggleAll(!allChecked),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        allChecked
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: allChecked
                            ? AppColors.primary
                            : const Color(0xFFCBD5E1),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '약관 전체 동의',
                        style: TextStyle(
                          color: allChecked
                              ? AppColors.textStrong
                              : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.66,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (terms.isEmpty)
                const _NoticeBox(message: '활성화된 약관이 없습니다.')
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: terms.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 0),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
        NurimBottomActionBar(
          primaryLabel: '다음',
          primaryEnabled: requiredChecked,
          isLoading: _submitting,
          onPrimaryPressed: () => _submitTerms(terms),
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
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: enabled ? () => onChanged(!checked) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      checked ? Icons.check_circle : Icons.check_circle_outline,
                      color: checked
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '(${term.requiredLabel}) ${term.termsName}',
                        style: TextStyle(
                          color: checked
                              ? AppColors.textStrong
                              : AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.66,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onOpen,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Icon(
                Icons.chevron_right,
                color: Color(0xFFCBD5E1),
                size: 16,
              ),
            ),
          ),
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
