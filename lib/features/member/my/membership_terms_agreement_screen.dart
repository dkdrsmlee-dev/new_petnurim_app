import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/page_header.dart';
import '../../signup/application/signup_providers.dart';
import '../../signup/domain/signup_terms.dart';
import '../../signup/terms_detail_screen.dart';

/// 멤버십 구독 약관 동의 화면 (USR-PAY-012).
///
/// 회원가입 약관 동의(`TermsScreen`, target=SIGNUP)와는 별개 — 로그인 사용자가
/// 멤버십 혜택 화면에서 "멤버십 즉시 구독하기"로 진입하는 구독 약관 동의 단계다.
/// 약관은 `GET /api/v1/terms?target=SUBSCRIPTION`(인증 불필요)에서 동적으로 받아
/// 렌더한다. 상세는 회원가입과 동일한 `TermsDetailScreen`(HTML)을 재사용.
///
/// "다음" 이후의 실제 구독(카드 등록/토스 빌링 + 백엔드 구독 API)이 아직 없어
/// 현재는 "준비 중" 토스트로 처리한다. 동의 저장 엔드포인트(구독용)도 없어
/// 동의는 클라이언트 게이트로만 사용한다.
class MembershipTermsAgreementScreen extends ConsumerStatefulWidget {
  const MembershipTermsAgreementScreen({super.key});

  @override
  ConsumerState<MembershipTermsAgreementScreen> createState() =>
      _MembershipTermsAgreementScreenState();
}

class _MembershipTermsAgreementScreenState
    extends ConsumerState<MembershipTermsAgreementScreen> {
  final Map<String, bool> _checkedTerms = {};

  @override
  Widget build(BuildContext context) {
    final termsState = ref.watch(subscriptionTermsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '',
        showDivider: false,
        onBackPressed: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: termsState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stackTrace) => _ErrorView(
            onRetry: () => ref.invalidate(subscriptionTermsProvider),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              const Text(
                '멤버십 구독을 위해\n약관 동의가 필요해요.',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.66,
                ),
              ),
              const SizedBox(height: 40),
              // 약관 전체 동의 (회색 박스)
              GestureDetector(
                onTap: terms.isEmpty ? null : () => _toggleAll(!allChecked),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _CheckCircle(checked: allChecked, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '약관 전체 동의',
                        style: TextStyle(
                          color: allChecked
                              ? AppColors.textStrong
                              : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight:
                              allChecked ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: -0.66,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (terms.isEmpty)
                const _EmptyBox(message: '표시할 약관이 없습니다.')
              else
                ...terms.map(
                  (term) => _TermTile(
                    term: term,
                    checked: _isChecked(term),
                    onToggle: () => _toggleTerm(term.termsId),
                    onOpen: () => _openTerm(term),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        NurimBottomActionBar(
          primaryLabel: '다음',
          primaryEnabled: requiredChecked,
          onPrimaryPressed: _onNext,
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
    final terms =
        ref.read(subscriptionTermsProvider).value ?? const <ActiveTerm>[];
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

  void _onNext() {
    // 실제 구독(카드 등록/토스 빌링 + 백엔드 구독 API)이 없어 준비 중 처리.
    ToastUtil.show(context, '준비 중인 기능입니다.');
  }

  void _openTerm(ActiveTerm term) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TermsDetailScreen(term: term)),
    );
  }
}

/// 멤버십 구독 약관 목록(target=SUBSCRIPTION). 회원가입용(`activeTermsProvider`,
/// target=SIGNUP)과 분리된 별도 provider. 약관 조회 메서드는 공용 재사용.
final subscriptionTermsProvider =
    FutureProvider.autoDispose<List<ActiveTerm>>((ref) {
  return ref
      .watch(signupRepositoryProvider)
      .fetchActiveTerms(target: 'SUBSCRIPTION');
});

/// 디자인 체크박스: 항상 채워진 원 + 흰 체크. 색만 상태에 따라 전환한다.
/// (미동의 #E8EBF1 회색 → 흰 체크가 은은 / 동의 #7F4FFF 보라 → 흰 체크 선명)
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked, required this.size});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? AppColors.primary : AppColors.borderLight,
      ),
      child: Icon(Icons.check, size: size * 0.62, color: Colors.white),
    );
  }
}

/// 약관 한 줄: 좌측(체크 + 라벨, 탭 시 동의 토글) / 우측(> , 탭 시 상세).
class _TermTile extends StatelessWidget {
  const _TermTile({
    required this.term,
    required this.checked,
    required this.onToggle,
    required this.onOpen,
  });

  final ActiveTerm term;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _CheckCircle(checked: checked, size: 21),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '(${term.requiredLabel}) ${term.termsName}',
                        style: TextStyle(
                          color: checked
                              ? AppColors.textStrong
                              : AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight:
                              checked ? FontWeight.w600 : FontWeight.w500,
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
                color: Color(0xFFC4CAD4),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            letterSpacing: -0.66,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '약관을 불러오지 못했습니다.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              letterSpacing: -0.66,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
