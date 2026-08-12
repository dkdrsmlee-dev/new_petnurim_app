import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/page_header.dart';
import '../../auth/domain/readable_auth_error.dart';
import '../../signup/domain/signup_terms.dart';
import '../../signup/terms_detail_screen.dart';
import '../data/membership_repository.dart';
import '../domain/payment_method_models.dart';
import '../widgets/card_issuer_icon.dart';
import 'membership_benefits_screen.dart';
import 'membership_complete_screen.dart';
import 'payment_method_select_sheet.dart';

/// 구독하기(결제 확인) 화면 (Figma 547:13693, USR-MBS-014).
///
/// 약관 동의 → 본인 명의 카드 선택 이후, 실제 결제 직전에 구독/결제 내용을
/// 확인시키는 화면. 결제 수단은 이 화면에서 다시 바꿀 수 있고(카드 선택 시트),
/// 하단 "N원 결제하기"를 눌러야 비로소 `POST /memberships`로 구독이 생성된다.
/// 백엔드는 부가세/공급가 breakdown 을 주지 않으므로 `monthlyFee`(부가세 포함가)
/// 기준으로 표기한다(부가세 = 포함가의 10/110, 다음 결제일 = 오늘 +1개월 추정).
class SubscribeConfirmScreen extends ConsumerStatefulWidget {
  const SubscribeConfirmScreen({
    super.key,
    required this.myPetId,
    required this.membershipMasterId,
    required this.membershipName,
    required this.monthlyFee,
    required this.initialCard,
    required this.activeCards,
    required this.termsHistoryIds,
    required this.terms,
  });

  final int myPetId;
  final int membershipMasterId;
  final String membershipName;
  final int monthlyFee;
  final PaymentMethod initialCard;

  /// 결제 수단 변경(카드 선택 시트)에 쓰는 활성 카드 목록.
  final List<PaymentMethod> activeCards;
  final List<int> termsHistoryIds;

  /// "멤버십 이용약관에 동의 >" 상세 보기용 구독 약관 목록.
  final List<ActiveTerm> terms;

  @override
  ConsumerState<SubscribeConfirmScreen> createState() =>
      _SubscribeConfirmScreenState();
}

class _SubscribeConfirmScreenState
    extends ConsumerState<SubscribeConfirmScreen> {
  late PaymentMethod _card = widget.initialCard;
  bool _submitting = false;

  /// 부가세 포함가 기준 세액(예: 10,000원 → 909원).
  int get _vat => (widget.monthlyFee * 10 / 110).round();

  /// 다음 결제일(결제 전이라 백엔드 값이 없어 오늘 +1개월로 추정).
  String get _nextBillingText {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, now.day);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${next.year}.${two(next.month)}.${two(next.day)}';
  }

  Future<void> _changeCard() async {
    final selectedId = await showPaymentCardSelectSheet(
      context,
      cards: widget.activeCards,
      selectedId: _card.userPaymentMethodId,
    );
    if (!mounted || selectedId == null) return;
    setState(() {
      _card = widget.activeCards.firstWhere(
        (c) => c.userPaymentMethodId == selectedId,
        orElse: () => _card,
      );
    });
  }

  /// "멤버십 이용약관에 동의 >" → 구독 약관 목록 바텀시트(이용약관/개인정보 처리방침).
  /// 약관은 직전 화면에서 이미 동의했으므로 여기선 열람용. 각 항목 > 로 상세(HTML).
  void _openTerms() {
    if (widget.terms.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      isScrollControlled: true,
      builder: (_) => _TermsListSheet(terms: widget.terms),
    );
  }

  Future<void> _pay() async {
    setState(() => _submitting = true);
    try {
      final result =
          await ref.read(membershipRepositoryProvider).subscribeWithPaymentMethod(
                myPetId: widget.myPetId,
                membershipMasterId: widget.membershipMasterId,
                userPaymentMethodId: _card.userPaymentMethodId,
                termsHistoryIds: widget.termsHistoryIds,
              );
      if (!mounted) return;
      // 결제 완료 화면 → 혜택 화면까지 popUntil 후 pop → 마이펫 상세 복귀.
      ref.invalidate(petMembershipProvider(widget.myPetId.toString()));
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MembershipCompleteScreen(membershipId: result.membershipId),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).popUntil(
        (route) => route.settings.name == MembershipBenefitsScreen.routeName,
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ToastUtil.show(context, readAuthErrorMessage(error, '멤버십 결제에 실패했습니다.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 디자인(547:13693): 흰 섹션들이 회색(구분) 배경으로 나뉜 "카드 스택" 형태.
    // 회색 페이지 위에 흰 섹션을 얹고 사이를 6px 회색으로 띄워 구분한다.
    return Scaffold(
      backgroundColor: AppColors.sectionGap,
      appBar: const NurimPageHeader(title: '구독하기', showDivider: false),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _whiteSection(_orderInfo()),
                  const SizedBox(height: 6),
                  _whiteSection(_paymentInfo()),
                  const SizedBox(height: 6),
                  _whiteSection(_paymentMethod()),
                  const SizedBox(height: 6),
                  _whiteSection(_agreeAndNotice()),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              child: _payButton(),
            ),
          ],
        ),
      ),
    );
  }

  /// 흰 배경 섹션 블록(좌우 16, 상하 24 패딩). 사이의 회색 갭이 구분선 역할.
  Widget _whiteSection(Widget child) => Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: child,
      );

  // ── 구독 정보 ──────────────────────────────────────────────
  Widget _orderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('구독 정보'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgGray,
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.membershipName.isEmpty ? '멤버십' : widget.membershipName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '매월 신용카드 자동결제',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.textDisabled),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '첫 결제 완료 후 리워드가 지급됩니다.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 결제 정보 ──────────────────────────────────────────────
  Widget _paymentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('결제 정보'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              _infoRow('월 이용료(부가세 포함)', '${formatThousands(widget.monthlyFee)}원'),
              const SizedBox(height: 12),
              // 부가세(하위 항목) — 작은 글씨·연한 색.
              Row(
                children: [
                  const Icon(Icons.subdirectory_arrow_right,
                      size: 16, color: AppColors.placeholder),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      '부가세',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: -0.66,
                        color: AppColors.placeholder,
                      ),
                    ),
                  ),
                  Text(
                    '${formatThousands(_vat)}원',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      letterSpacing: -0.66,
                      color: AppColors.placeholder,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow('결제 방식', '월 정기 결제'),
              const SizedBox(height: 12),
              _infoRow('다음 결제일', _nextBillingText),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                '총 결제 금액',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Text(
              '${formatThousands(widget.monthlyFee)}원',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.4,
                letterSpacing: -0.66,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 라벨(Medium #87909e) + 값(SemiBold #51565f) 한 줄.
  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.66,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.66,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ── 결제 수단 ──────────────────────────────────────────────
  Widget _paymentMethod() {
    // 카드가 2개 이상일 때만 변경 가능(> 화살표·탭). 1개면 변경 대상이 없음.
    final canChange = widget.activeCards.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('결제 수단'),
        const SizedBox(height: 12),
        InkWell(
          onTap: canChange ? _changeCard : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CardIssuerIcon(issuerName: _card.cardIssuerName),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _card.cardLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.66,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                if (canChange)
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 약관 동의 링크 + 유의사항 ────────────────────────────────
  Widget _agreeAndNotice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _openTerms,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '멤버십 이용약관에 동의',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.66,
                      color: AppColors.textStrong,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '결제 시 유의사항',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: AppColors.textMuted,
                ),
              ),
              SizedBox(height: 12),
              _Bullet('결제 후 즉시 멤버십이 활성화 됩니다.'),
              SizedBox(height: 8),
              _Bullet('해지는 맴버십 관리에서 가능합니다.'),
              SizedBox(height: 8),
              _Bullet('회원탈퇴 시 잔여 기간을 모두 사용 후 멤버십 탈퇴가 가능합니다.'),
            ],
          ),
        ),
      ],
    );
  }

  // ── 하단 결제 버튼 ─────────────────────────────────────────
  Widget _payButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _submitting ? null : _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${formatThousands(widget.monthlyFee)}원',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.66,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      '결제하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        letterSpacing: -0.66,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: -0.66,
        color: AppColors.textStrong,
      ),
    );
  }
}

/// 멤버십 이용약관 목록 바텀시트. 구독 약관(이용약관/개인정보 처리방침)을 나열하고
/// 각 항목 탭 시 상세(HTML)를 시트 위에 띄운다(둘 다 열람 후 X로 닫기).
class _TermsListSheet extends StatelessWidget {
  const _TermsListSheet({required this.terms});

  final List<ActiveTerm> terms;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '멤버십 이용약관',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.66,
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        size: 24, color: AppColors.textStrong),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                itemCount: terms.length,
                itemBuilder: (context, i) {
                  final t = terms[i];
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TermsDetailScreen(term: t)),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '(${t.requiredLabel}) ${t.termsName}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: -0.66,
                                color: AppColors.textStrong,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 20, color: AppColors.textDisabled),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: SizedBox(
            width: 3,
            height: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.4,
              letterSpacing: -0.66,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
