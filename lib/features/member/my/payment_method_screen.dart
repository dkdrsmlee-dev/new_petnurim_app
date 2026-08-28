import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import '../data/membership_repository.dart';
import '../data/payment_method_repository.dart';
import '../domain/payment_method_models.dart';
import '../widgets/card_issuer_icon.dart';
import 'toss_billing_test_webview_screen.dart';

/// 결제수단 관리 화면(USR-PAY-011, Figma 281:16702).
/// `GET /payment-methods` 목록 + 기본 결제수단 변경(탭) + 카드 삭제(⋮ → 확인 → DELETE).
/// "결제카드 추가"는 별도 등록 플로우로 분리(현재 준비 중 토스트).
class PaymentMethodScreen extends ConsumerWidget {
  const PaymentMethodScreen({super.key});

  static const Color _cardNameColor = Color(0xFF51565F); // Figma color/gray/100

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentMethodsProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const NurimPageHeader(title: '결제수단'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, _) => _buildError(context, ref, err),
                data: (cards) {
                  if (cards.isEmpty) return _buildEmpty();
                  // 최신 등록순(id 내림차순) 안정 정렬 — 기본 결제수단을 바꿔도
                  // 행 위치는 고정되고 ✓ 체크만 이동한다(기획서 USR_MYP_022).
                  final sorted = [...cards]
                    ..sort((a, b) => b.userPaymentMethodId
                        .compareTo(a.userPaymentMethodId));
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final pm in sorted) _buildRow(context, ref, pm),
                    ],
                  );
                },
              ),
            ),
            // 결제카드 추가 — 별도 등록 플로우(준비 중)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => _addCard(context, ref),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '결제카드 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.66,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.add, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, WidgetRef ref, PaymentMethod pm) {
    // 활성 & 기본 아님 → 탭 시 기본 결제수단으로 변경.
    final tappable = pm.isActive && !pm.isDefault;
    return InkWell(
      onTap: tappable ? () => _setDefault(context, ref, pm) : null,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Row(
          children: [
            CardIssuerIcon(
              issuerName: pm.cardIssuerName,
              disabled: pm.isRestricted,
            ),
            const SizedBox(width: 8),
            Text(
              pm.cardLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.66,
                height: 1.4,
                color: pm.isRestricted
                    ? AppColors.textDisabled
                    : _cardNameColor,
              ),
            ),
            if (pm.isRestricted) ...[
              const SizedBox(width: 8),
              const Text(
                '사용제한',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.66,
                  height: 1.4,
                  color: AppColors.errorSoft,
                ),
              ),
            ],
            if (pm.isDefault) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, size: 24, color: AppColors.primary),
            ],
            const Spacer(),
            _buildMoreMenu(context, ref, pm),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref, PaymentMethod pm) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 24, color: AppColors.textDisabled),
      padding: EdgeInsets.zero,
      color: Colors.white,
      // Figma Edit list(531:15268): border #D6DBE4 + 옅은 그림자
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (value) {
        if (value == 'delete') _confirmDelete(context, ref, pm);
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '카드 삭제하기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF51565F), // Figma text-color/primary
                  letterSpacing: -0.66,
                  height: 1.4,
                ),
              ),
              const SizedBox(width: 6),
              SvgPicture.asset(
                'assets/images/ic_trash_20.svg',
                width: 20,
                height: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PaymentMethod pm) {
    showDialog<void>(
      context: context,
      builder: (_) => EdgeButtonDialog(
        title: '카드를 삭제할까요?',
        content: '삭제 후 다시 사용하려면\n재등록이 필요합니다.',
        cancelText: '취소',
        confirmText: '확인',
        onConfirm: () => _doDelete(context, ref, pm),
      ),
    );
  }

  Future<void> _doDelete(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod pm,
  ) async {
    try {
      await ref
          .read(paymentMethodRepositoryProvider)
          .deletePaymentMethod(pm.userPaymentMethodId);
      ref.invalidate(paymentMethodsProvider);
      if (context.mounted) {
        ToastUtil.show(context, '카드가 삭제되었습니다.');
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtil.show(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod pm,
  ) async {
    try {
      await ref
          .read(paymentMethodRepositoryProvider)
          .setDefaultPaymentMethod(pm.userPaymentMethodId);
      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (context.mounted) {
        ToastUtil.show(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  /// 결제카드 추가: 토스 Billing Auth(카드 등록창) → authKey →
  /// `POST /payment-methods`. 등록 폼은 토스 PG(보안·PCI)가 담당한다.
  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    // 백엔드 secretKey 와 짝인 상점 clientKey(Billing Auth 필수).
    final String clientKey;
    try {
      clientKey =
          await ref.read(membershipRepositoryProvider).getTossClientKey();
    } catch (_) {
      if (context.mounted) {
        ToastUtil.show(context, '결제 설정을 불러오지 못했습니다.');
      }
      return;
    }
    if (!context.mounted) return;

    // 회원 지갑용 customerKey. Billing Auth 와 등록 API 에 동일하게 전달해야 한다.
    final customerKey = 'pn_user_${DateTime.now().millisecondsSinceEpoch}';
    final authKey = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => TossBillingTestWebViewScreen(
          customerKey: customerKey,
          clientKey: clientKey,
        ),
      ),
    );
    if (!context.mounted || authKey == null || authKey.isEmpty) return;

    try {
      await ref.read(paymentMethodRepositoryProvider).registerPaymentMethod(
            authKey: authKey,
            customerKey: customerKey,
          );
      ref.invalidate(paymentMethodsProvider);
      if (context.mounted) {
        ToastUtil.show(context, '결제 카드 등록이 완료되었습니다.');
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtil.show(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off_outlined,
              size: 48, color: AppColors.placeholder),
          SizedBox(height: 12),
          Text(
            '등록된 결제수단이 없어요.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFA6262), size: 48),
          const SizedBox(height: 12),
          const Text(
            '결제수단을 불러오지 못했습니다.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(paymentMethodsProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
