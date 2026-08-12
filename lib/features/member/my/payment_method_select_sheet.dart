import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/payment_method_models.dart';
import '../widgets/card_issuer_icon.dart';

/// 본인 명의 카드 선택 바텀시트(Figma 277:14037, USR-PAY-011).
///
/// 멤버십 즉시 구독 시 약관 동의 후, 이미 등록된(활성) 카드가 2개 이상일 때
/// 결제할 카드를 고르는 단계. 카드 탭 시 그 카드의
/// [PaymentMethod.userPaymentMethodId]를 반환하고(선택+진행), X·바깥 탭으로
/// 닫으면 null(취소)을 반환한다. 카드 행 UI는 결제수단 관리 화면과 동일하게
/// [CardIssuerIcon] + [PaymentMethod.cardLabel]을 재사용한다.
Future<int?> showPaymentCardSelectSheet(
  BuildContext context, {
  required List<PaymentMethod> cards,
  int? selectedId,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99000000), // scrim/60 (rgba 0,0,0,0.6)
    isScrollControlled: true,
    builder: (_) => _PaymentCardSelectSheet(cards: cards, selectedId: selectedId),
  );
}

class _PaymentCardSelectSheet extends StatelessWidget {
  const _PaymentCardSelectSheet({required this.cards, this.selectedId});

  final List<PaymentMethod> cards;
  final int? selectedId;

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
            // 제목 + 닫기(X)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '본인 명의 카드 선택',
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
            const SizedBox(height: 16),
            // 카드 목록(활성 카드) — 탭 시 해당 카드로 결제 진행.
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                itemCount: cards.length,
                itemBuilder: (context, i) {
                  final pm = cards[i];
                  final selected = pm.userPaymentMethodId == selectedId;
                  return InkWell(
                    onTap: () =>
                        Navigator.of(context).pop(pm.userPaymentMethodId),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          CardIssuerIcon(issuerName: pm.cardIssuerName),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pm.cardLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: -0.66,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 16),
                            const Icon(Icons.check,
                                size: 24, color: AppColors.primary),
                          ],
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
