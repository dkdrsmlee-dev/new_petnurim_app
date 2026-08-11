import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import '../../auth/domain/readable_auth_error.dart';
import '../../signup/application/signup_providers.dart';
import '../../signup/domain/signup_terms.dart';
import '../../signup/terms_detail_screen.dart';
import '../data/membership_repository.dart';
import '../data/payment_method_repository.dart';
import '../domain/payment_method_models.dart';
import 'membership_benefits_screen.dart';
import 'membership_complete_screen.dart';
import 'toss_billing_test_webview_screen.dart';

/// 멤버십 구독 약관 동의 화면 (USR-PAY-012).
///
/// 회원가입 약관 동의(`TermsScreen`, target=SIGNUP)와는 별개 — 로그인 사용자가
/// 멤버십 혜택 화면에서 "멤버십 즉시 구독하기"로 진입하는 구독 약관 동의 단계다.
/// 약관은 `GET /api/v1/terms?target=SUBSCRIPTION`(인증 불필요)에서 동적으로 받아
/// 렌더한다. 상세는 회원가입과 동일한 `TermsDetailScreen`(HTML)을 재사용.
///
/// "다음" → `POST /memberships/validate`(가입 사전 검증) 통과 후 결제수단 유무로
/// 분기한다: 등록된 카드가 있으면 그 카드(userPaymentMethodId)로 바로 구독,
/// 없으면 (디자인에 없는 중간 화면 없이) 토스 카드 등록창을 띄워 지갑에 등록한 뒤
/// 그 카드로 구독한다. 동의한 약관의 termsHistoryId 를 수집해 검증·가입에 사용하며,
/// 멤버십은 펫별이라 [myPetId]·[membershipMasterId]를 관통시킨다.
class MembershipTermsAgreementScreen extends ConsumerStatefulWidget {
  const MembershipTermsAgreementScreen({
    super.key,
    required this.myPetId,
    required this.membershipMasterId,
  });

  /// 가입 대상 마이펫 ID.
  final int myPetId;

  /// 가입할 멤버십 종류 ID(guide 의 membershipId).
  final int membershipMasterId;

  @override
  ConsumerState<MembershipTermsAgreementScreen> createState() =>
      _MembershipTermsAgreementScreenState();
}

class _MembershipTermsAgreementScreenState
    extends ConsumerState<MembershipTermsAgreementScreen> {
  final Map<String, bool> _checkedTerms = {};
  bool _validating = false;

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
          isLoading: _validating,
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

  /// 가입 사전 검증(POST /memberships/validate) 통과 시 결제카드 등록으로 이동.
  Future<void> _onNext() async {
    final terms =
        ref.read(subscriptionTermsProvider).value ?? const <ActiveTerm>[];
    final termsHistoryIds = terms
        .where(_isChecked)
        .map((t) => t.termsHistoryIdInt)
        .whereType<int>()
        .toList();

    setState(() => _validating = true);
    try {
      final valid = await ref.read(membershipRepositoryProvider).validate(
            myPetId: widget.myPetId,
            membershipMasterId: widget.membershipMasterId,
            termsHistoryIds: termsHistoryIds,
          );
      if (!mounted) return;
      if (!valid) {
        ToastUtil.show(context, '지금은 가입할 수 없는 상태입니다. 다시 확인해 주세요.');
        return;
      }
      // 결제수단 분기: 등록된 활성 카드가 있으면 그 카드로 바로 구독(카드 등록 생략),
      // 없으면 토스 카드 등록 화면으로 이동.
      List<PaymentMethod> cards;
      try {
        cards = await ref.read(paymentMethodsProvider.future);
      } catch (_) {
        cards = const [];
      }
      if (!mounted) return;
      final active = cards.where((c) => c.isActive).toList();
      if (active.isNotEmpty) {
        final card =
            active.firstWhere((c) => c.isDefault, orElse: () => active.first);
        await _subscribeWithExistingCard(
            card.userPaymentMethodId, termsHistoryIds);
      } else {
        await _registerCardThenSubscribe(termsHistoryIds);
      }
    } catch (error) {
      if (!mounted) return;
      ToastUtil.show(context, readAuthErrorMessage(error, '가입 검증에 실패했습니다.'));
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  /// 등록된 결제수단으로 바로 구독(카드 등록 단계 생략) → 결제 완료 화면.
  Future<void> _subscribeWithExistingCard(
    int userPaymentMethodId,
    List<int> termsHistoryIds,
  ) async {
    try {
      final result = await ref
          .read(membershipRepositoryProvider)
          .subscribeWithPaymentMethod(
            myPetId: widget.myPetId,
            membershipMasterId: widget.membershipMasterId,
            userPaymentMethodId: userPaymentMethodId,
            termsHistoryIds: termsHistoryIds,
          );
      await _goComplete(result.membershipId);
    } catch (error) {
      if (!mounted) return;
      ToastUtil.show(
          context, readAuthErrorMessage(error, '멤버십 가입에 실패했습니다.'));
    }
  }

  /// 결제수단 미등록: (디자인에 없는 중간 화면 없이) 약관 "다음"에서 바로 토스
  /// 카드 등록창을 띄운 뒤, 등록한 카드를 지갑에 남기고 그 카드로 구독한다.
  Future<void> _registerCardThenSubscribe(List<int> termsHistoryIds) async {
    final String clientKey;
    try {
      clientKey =
          await ref.read(membershipRepositoryProvider).getTossClientKey();
    } catch (_) {
      if (mounted) ToastUtil.show(context, '결제 설정을 불러오지 못했습니다.');
      return;
    }
    if (!mounted) return;

    final customerKey = 'pn_user_${DateTime.now().millisecondsSinceEpoch}';
    final authKey = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => TossBillingTestWebViewScreen(
          customerKey: customerKey,
          clientKey: clientKey,
        ),
      ),
    );
    if (!mounted || authKey == null || authKey.isEmpty) return; // 취소/실패

    try {
      // 토스 카드를 결제수단 지갑에 먼저 등록해 목록에도 남긴 뒤, 그 카드로 구독.
      await ref
          .read(paymentMethodRepositoryProvider)
          .registerPaymentMethod(authKey: authKey, customerKey: customerKey);
      ref.invalidate(paymentMethodsProvider);
      final cards = await ref.read(paymentMethodsProvider.future);
      if (!mounted) return;
      final active = cards.where((c) => c.isActive).toList();
      if (active.isEmpty) {
        throw const FormatException('등록된 결제수단을 확인할 수 없습니다.');
      }
      final card =
          active.firstWhere((c) => c.isDefault, orElse: () => active.first);
      final result = await ref
          .read(membershipRepositoryProvider)
          .subscribeWithPaymentMethod(
            myPetId: widget.myPetId,
            membershipMasterId: widget.membershipMasterId,
            userPaymentMethodId: card.userPaymentMethodId,
            termsHistoryIds: termsHistoryIds,
          );
      if (!mounted) return;
      // 카드 등록 완료 다이얼로그(748:50978) → 결제 완료 화면.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EdgeButtonDialog(
          title: '결제 카드가 정상적으로\n등록되었습니다.',
          confirmText: '확인',
          onConfirm: () {},
        ),
      );
      await _goComplete(result.membershipId);
    } catch (error) {
      if (!mounted) return;
      ToastUtil.show(
          context, readAuthErrorMessage(error, '카드 등록/구독에 실패했습니다.'));
    }
  }

  /// 결제 완료 화면 → 혜택 화면까지 popUntil 후 pop → 마이펫 상세 복귀.
  Future<void> _goComplete(int membershipId) async {
    ref.invalidate(petMembershipProvider(widget.myPetId.toString()));
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MembershipCompleteScreen(membershipId: membershipId),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).popUntil(
      (route) => route.settings.name == MembershipBenefitsScreen.routeName,
    );
    Navigator.of(context).pop();
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
