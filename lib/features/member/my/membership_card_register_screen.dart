import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import '../../auth/domain/readable_auth_error.dart';
import '../data/membership_repository.dart';
import 'membership_benefits_screen.dart';
import 'toss_billing_test_webview_screen.dart';

/// 멤버십 구독 결제카드 등록 화면 (USR-PAY-011).
///
/// 국내 표준상 카드정보는 앱이 직접 받지 않고 PG(토스페이먼츠) 결제창에서 입력받는다.
/// "카드 등록하고 구독하기" → 토스 Billing Auth(카드 등록창)에서 authKey 를 받고,
/// 그 authKey/customerKey 로 `POST /api/v1/memberships` 를 호출해 실제 구독을 생성한다.
///
/// 현재는 토스 **공개 테스트 clientKey**를 쓰므로 실제 청구는 없지만, 백엔드 가입은
/// 실제로 이뤄진다. 실 상점 clientKey 준비 시 [TossBillingTestWebViewScreen] 의
/// 키만 교체하면 된다.
class MembershipCardRegisterScreen extends ConsumerStatefulWidget {
  const MembershipCardRegisterScreen({
    super.key,
    required this.myPetId,
    required this.membershipMasterId,
    required this.termsHistoryIds,
  });

  final int myPetId;
  final int membershipMasterId;
  final List<int> termsHistoryIds;

  @override
  ConsumerState<MembershipCardRegisterScreen> createState() =>
      _MembershipCardRegisterScreenState();
}

class _MembershipCardRegisterScreenState
    extends ConsumerState<MembershipCardRegisterScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _submitting) return;
        _confirmCancel();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: NurimPageHeader(
          title: '결제 카드 등록',
          onBackPressed: _submitting ? null : _confirmCancel,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(child: _PgPlaceholder()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _submitting ? null : _startBilling,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '카드 등록하고 구독하기',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.66,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1) 토스 Billing Auth(카드 등록창) → authKey  2) POST /memberships 로 구독 생성.
  Future<void> _startBilling() async {
    // customerKey 는 Billing Auth 와 가입 API 에 동일하게 전달해야 한다.
    final customerKey =
        'pn_${widget.myPetId}_${DateTime.now().millisecondsSinceEpoch}';
    final authKey = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            TossBillingTestWebViewScreen(customerKey: customerKey),
      ),
    );
    if (!mounted || authKey == null || authKey.isEmpty) return; // 취소/실패

    setState(() => _submitting = true);
    try {
      await ref.read(membershipRepositoryProvider).create(
            myPetId: widget.myPetId,
            membershipMasterId: widget.membershipMasterId,
            customerKey: customerKey,
            authKey: authKey,
            termsHistoryIds: widget.termsHistoryIds,
          );
      if (!mounted) return;
      _showRegistered();
    } catch (error) {
      if (!mounted) return;
      ToastUtil.show(context, readAuthErrorMessage(error, '멤버십 가입에 실패했습니다.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 카드 등록 중단 확인(디자인: "카드등록을 중단하시겠어요?").
  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '카드등록을 중단하시겠어요?',
        content: '입력한 카드 정보는 저장되지 않아요.',
        cancelText: '나가기',
        confirmText: '계속 등록하기',
        onCancel: () {
          Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
          Navigator.of(context).pop(); // 카드 등록 화면 이탈
        },
        onConfirm: () {}, // 계속 등록: 다이얼로그만 닫힘(EdgeButtonDialog가 자동 pop)
      ),
    );
  }

  /// 가입 완료 다이얼로그(단일 확인). 확인 시 구독 플로우(카드→약관→혜택)를
  /// 걷어내고 마이펫 상세로 복귀한다.
  void _showRegistered() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '결제 카드가 정상적으로\n등록되었습니다.',
        confirmText: '확인',
        onConfirm: () {
          // 혜택 화면까지 되돌린 뒤(popUntil) 한 번 더 pop → 마이펫 상세로 복귀.
          Navigator.of(context).popUntil(
            (route) => route.settings.name == MembershipBenefitsScreen.routeName,
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// PG(토스) 결제창 안내.
class _PgPlaceholder extends StatelessWidget {
  const _PgPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.bgGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card,
                size: 34,
                color: AppColors.placeholder,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '카드 등록 (토스페이먼츠)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textStrong,
                letterSpacing: -0.66,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '아래 버튼을 누르면 토스 카드 등록창이 열립니다.\n'
              '카드 등록을 마치면 멤버십 구독이 완료됩니다.\n'
              '(현재 토스 테스트 모드 — 실제 카드 청구는 없습니다.)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.5,
                letterSpacing: -0.66,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
