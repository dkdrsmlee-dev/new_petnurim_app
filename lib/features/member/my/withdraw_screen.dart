
import 'package:flutter/material.dart';
import '../../../core/widgets/bullit_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_bootstrap.dart';
import '../../../app/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/selection_control.dart';
import '../data/common_code_repository.dart';
import '../data/member_repository.dart';
import '../data/membership_repository.dart';
import '../domain/common_code.dart';
import '../domain/membership_models.dart';
import '../../../core/theme/app_colors.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  // 탈퇴 사유는 백엔드 공통코드(WITHDRAW_REASON_TYPE)에서 받아온다(withdrawReasonsProvider).
  // 조회 실패/로딩 시 사용할 fallback 목록.
  static const List<CommonCode> _fallbackReasons = [
    CommonCode(codeVal: 'LOW_USAGE', codeNm: '사용 빈도가 낮아요.'),
    CommonCode(codeVal: 'FEATURE_LACK', codeNm: '원하는 기능/서비스가 없어요.'),
    CommonCode(codeVal: 'INCONVENIENT', codeNm: '서비스 이용이 불편해요.'),
    CommonCode(codeVal: 'PRICE', codeNm: '가격이 부담돼요.'),
    CommonCode(codeVal: 'PRIVACY', codeNm: '개인정보 보안이 우려돼요.'),
    CommonCode(codeVal: 'CUSTOMER_SERVICE', codeNm: '고객 응대가 불만족스러워요.'),
    CommonCode(codeVal: 'ETC', codeNm: '직접 입력'),
  ];

  // 직접 입력(기타) 코드값
  static const String _customReasonCode = 'ETC';

  String? _selectedReasonCode; // 선택된 사유 codeVal
  final TextEditingController _customReasonController = TextEditingController();
  bool _agreed = false; // 동의 여부 체크박스 상태
  bool _isWithdrawing = false; // 탈퇴 로딩 상태
  String? _errorMessage;


  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 탈퇴 사유: 백엔드 공통코드 조회값 우선, 로딩/실패 시 fallback.
    final fetched = ref.watch(withdrawReasonsProvider).asData?.value;
    final reasons =
        (fetched != null && fetched.isNotEmpty) ? fetched : _fallbackReasons;
    // 활성 구독 목록(있으면 상단 안내 박스 표시 — 196:7510 "구독 서비스 있음").
    final activeSubs =
        ref.watch(withdrawActiveSubscriptionsProvider).asData?.value ??
            const <MembershipDetail>[];
    return Scaffold(
      appBar: const NurimPageHeader(title: '회원 탈퇴'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 90, // Leave space for bottom buttons
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // Figma: 좌우 16
                children: [
                  // 1. 유의사항 안내 섹션
                  const Text(
                    '탈퇴 전 꼭 확인해 주세요.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 12), // Figma: 타이틀 ↔ 박스 12
                  // 구독 서비스 있음(196:7510): 활성 구독을 모두 표시.
                  if (activeSubs.isNotEmpty) ...[
                    _buildActiveSubscriptionBox(activeSubs),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSoft,
                      borderRadius: BorderRadius.circular(12), // Figma Notice
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NoticeBullet('탈퇴 시 계정 및 데이터는 복구되지 않습니다.'),
                        SizedBox(height: 8),
                        _NoticeBullet('보유 중인 리워드/포인트는 모두 소멸됩니다.'),
                        SizedBox(height: 8),
                        _NoticeBullet('진행 중인 서비스/구독은 잔여 기간을 모두 소진한 후 탈퇴 가능합니다.'),
                        SizedBox(height: 8),
                        _NoticeBullet('탈퇴 후 30일 동안 재가입이 불가합니다.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32), // Figma: 박스 ↔ 탈퇴 사유 32

                  // 2. 탈퇴 사유 선택 섹션
                  const Text(
                    '탈퇴 사유를 알려주세요.(선택)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 12), // Figma: 타이틀 ↔ 목록 12
                  ...reasons.map((reason) {
                    return SelectionControl<String>(
                      style: SelectionControlStyle.radio,
                      text: reason.codeNm,
                      value: reason.codeVal,
                      groupValue: _selectedReasonCode,
                      onChanged: (val) {
                        setState(() {
                          _selectedReasonCode = val;
                        });
                      },
                    );
                  }),

                  // 직접 입력(ETC) 선택 시 텍스트 영역 활성화
                  if (_selectedReasonCode == _customReasonCode) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customReasonController,
                      maxLines: 4,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: '내용을 작성해 주세요.',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.bgSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.textStrong),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: const TextStyle(fontSize: 14, color: AppColors.textStrong),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // 3. 회원탈퇴 동의하기 섹션
                  SelectionControl<bool>(
                    style: SelectionControlStyle.checkbox,
                    text: '유의사항을 모두 확인하였으며, 이에 동의합니다.',
                    value: _agreed,
                    onChanged: (val) {
                      setState(() {
                        _agreed = val ?? false;
                      });
                    },
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            
            // 4. 하단 고정 회원탈퇴 버튼
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isWithdrawing ? null : () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderLight),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _agreed && !_isWithdrawing ? _handleWithdrawClick : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.borderLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isWithdrawing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  '탈퇴하기',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: _agreed ? Colors.white : AppColors.placeholder,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 탈퇴 버튼 클릭 시 처리 로직
  void _handleWithdrawClick() {
    _showWithdrawConfirmAlert();
  }

  // 2) 일반 탈퇴 진행 확인 팝업
  void _showWithdrawConfirmAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x99000000),
      builder: (context) {
        // Figma 201:5663 — 버튼이 카드 모서리까지 꽉 찬 형태
        return EdgeButtonDialog(
          title: '정말 탈퇴하시겠어요?',
          content: '탈퇴 후에는 계정 정보와\n이용 내역을 복구할 수 없어요.',
          cancelText: '취소',
          confirmText: '탈퇴하기',
          onConfirm: _executeWithdraw,
        );
      },
    );
  }

  /// 활성 구독 안내 박스(196:7510) — 구독 펫마다 "구독 멤버십 | 브론즈 (종료일까지)".
  Widget _buildActiveSubscriptionBox(List<MembershipDetail> subs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        // Figma Membership info(203:6021): radius 12, 보더 #D6DBE4
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < subs.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '구독 멤버십',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // Figma Body/semibold/md
                    height: 1.4,
                    color: AppColors.textMuted, // #51565F
                    letterSpacing: -0.66,
                  ),
                ),
                Flexible(
                  child: Text(
                    '${subs[i].membershipName} (${_periodDot(subs[i].periodEndDt)}까지)',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15, // Figma Body/medium/sm
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: Color(0xFFFF5F5F), // red/60 강조
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// yyyy-MM-dd[ HH:mm:ss] → "yyyy.MM.dd".
  String _periodDot(String dt) {
    final s = dt.trim().length >= 10 ? dt.trim().substring(0, 10) : dt.trim();
    return s.replaceAll('-', '.');
  }

  /// 구독 기간이 남아 탈퇴가 보류된 경우 안내 팝업(USR-MIF-025, Figma 201:5927).
  /// 확인만 있는 단일 버튼. 로그인 상태는 유지된다.
  void _showSubscriptionActiveDialog(String effectiveDt) {
    showDialog(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (_) => EdgeButtonDialog(
        title: '${_effectiveDateKor(effectiveDt)}까지\n구독 중인 서비스가 있어요.',
        content: '남은 구독 기간이 종료된 후\n다시 탈퇴를 신청해 주세요.',
        confirmText: '확인',
        onConfirm: () {},
      ),
    );
  }

  /// yyyy-MM-dd[ HH:mm:ss] → "yyyy년 M월 dd일".
  String _effectiveDateKor(String dt) {
    final s = dt.trim().length >= 10 ? dt.trim().substring(0, 10) : dt.trim();
    final parts = s.split('-');
    if (parts.length != 3) return s;
    final m = int.tryParse(parts[1]) ?? parts[1];
    return '${parts[0]}년 $m월 ${parts[2]}일';
  }

  // 실제 API를 통한 회원탈퇴 수행
  Future<void> _executeWithdraw() async {
    setState(() {
      _isWithdrawing = true;
      _errorMessage = null;
    });

    final reasons =
        ref.read(withdrawReasonsProvider).asData?.value ?? _fallbackReasons;
    final reasonCode = _selectedReasonCode ?? _customReasonCode;

    // 사유 텍스트: 직접입력이면 입력값, 아니면 선택 코드의 codeNm
    String reasonText = '앱에서 회원탈퇴 요청';
    if (_selectedReasonCode == _customReasonCode &&
        _customReasonController.text.trim().isNotEmpty) {
      reasonText = _customReasonController.text.trim();
    } else if (_selectedReasonCode != null) {
      for (final code in reasons) {
        if (code.codeVal == _selectedReasonCode) {
          reasonText = code.codeNm;
          break;
        }
      }
    }

    try {
      final result = await ref.read(memberRepositoryProvider).withdraw(
            reasonCode: reasonCode,
            reasonText: reasonText,
          );

      if (!mounted) return;

      // 구독 기간이 남아 탈퇴 보류(PENDING) → 로그아웃하지 않고 안내 팝업(201:5927).
      if (result.isPending) {
        _showSubscriptionActiveDialog(result.effectiveDt);
        return;
      }

      // 즉시 탈퇴 완료(COMPLETED) → 토큰 정리 후 로그인 화면으로.
      await ref.read(tokenStorageProvider).clearTokens();
      ref.invalidate(appBootstrapStateProvider);

      if (!mounted) return;

      ToastUtil.show(context, '회원탈퇴가 성공적으로 처리되었습니다.');

      context.go(AppRoutes.authStart);
    } catch (e) {
      if (!mounted) return;
      
      final isUnauthorized = (e is ApiException && e.statusCode == 401) ||
          e.toString().contains('401') ||
          e.toString().contains('로그인이 만료');

      if (isUnauthorized) {
        // 로그인 만료인 경우 로컬 토큰 정리 및 세션 클리어 후 화면 이동
        await ref.read(tokenStorageProvider).clearTokens();
        ref.invalidate(appBootstrapStateProvider);

        if (mounted) {
          ToastUtil.show(context, '로그인 세션이 만료되었습니다. 다시 로그인해 주세요.');
          context.go(AppRoutes.authStart);
        }
      } else {
        setState(() {
          _errorMessage = '회원탈퇴 중 오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });
      }
    }
  }
}

// 불릿 항목 위젯
/// Figma `Bullet text`(198:4561) 인스턴스 — 점 #A2ADBE, 텍스트 15 Medium #87909E.
class _NoticeBullet extends StatelessWidget {
  const _NoticeBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return BullitText(
      text: text,
      bulletColor: AppColors.placeholder, // Figma Bulit #A2ADBE
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
        letterSpacing: -0.66,
      ),
    );
  }
}
