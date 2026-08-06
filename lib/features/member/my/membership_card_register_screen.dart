import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import 'membership_benefits_screen.dart';
import 'toss_billing_test_webview_screen.dart';

/// 멤버십 구독 결제카드 등록 화면 (USR-PAY-011) — PG(토스페이먼츠) 연동 자리.
///
/// 국내 표준상 카드번호/CVC/비밀번호는 앱이 직접 받지 않고 PG의 보안 결제창에서
/// 입력받는다(카드정보 직접취급 회피). 따라서 Figma의 커스텀 카드 폼은 사용하지
/// 않고, 이 화면에는 **토스 자동결제(빌링) WebView**가 들어간다.
///
/// 현재는 백엔드 PG 연동(상점 clientKey/secretKey, billingKey 발급·저장 API)이
/// 없어, 흐름 확인을 위해 **토스 공개 테스트 clientKey**로 카드 등록창(테스트)만
/// 미리 띄운다([TossBillingTestWebViewScreen]). 실제 billingKey 발급·카드 저장·
/// 구독 생성은 백엔드가 준비되면 연결한다. 완료/중단 다이얼로그는 디자인대로.
class MembershipCardRegisterScreen extends StatefulWidget {
  const MembershipCardRegisterScreen({super.key});

  @override
  State<MembershipCardRegisterScreen> createState() =>
      _MembershipCardRegisterScreenState();
}

class _MembershipCardRegisterScreenState
    extends State<MembershipCardRegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmCancel();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: NurimPageHeader(
          title: '결제 카드 등록',
          onBackPressed: _confirmCancel,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(child: _PgPlaceholder()),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 토스 테스트 카드 등록창 열기(실동작 대신 UI 미리보기).
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _openTossTest,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '카드 등록창 열기 (토스 테스트)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.66,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 토스 테스트창 없이 흐름(완료 다이얼로그)만 확인하는 폴백.
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _showRegistered,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '등록 완료 미리보기 (임시)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: -0.66,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 토스 테스트 카드 등록창을 띄우고, success 콜백(authKey 도달) 시 완료 처리.
  Future<void> _openTossTest() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const TossBillingTestWebViewScreen(),
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      _showRegistered();
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

  /// 등록 완료 다이얼로그(단일 확인). 확인 시 구독 플로우(카드→약관→혜택)를
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
              '아래 버튼을 누르면 토스 카드 등록창(테스트)이 열립니다.\n'
              '지금은 테스트 모드라 실제 결제·카드 저장은 되지 않으며,\n'
              '백엔드 PG 연동이 준비되면 실제 등록으로 연결됩니다.',
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
