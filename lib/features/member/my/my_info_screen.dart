import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/app_bootstrap.dart';
import '../../../app/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/address_card.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/popup_header.dart';
import '../../../core/widgets/edge_button_dialog.dart';
import '../../auth/application/auth_providers.dart';
import '../../signup/kcp_cert_webview_screen.dart';
import '../data/member_repository.dart';
import '../domain/member_info.dart';
import '../../../core/theme/app_colors.dart';

class AddressNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void updateAddress(String? address) {
    state = address;
  }
}

final addressOverrideProvider = NotifierProvider<AddressNotifier, String?>(
  AddressNotifier.new,
);

class MyInfoScreen extends ConsumerStatefulWidget {
  const MyInfoScreen({super.key});

  @override
  ConsumerState<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends ConsumerState<MyInfoScreen> {
  bool _isChangingPhone = false; // 휴대폰 번호 변경 진행 중(중복 실행 방지)

  @override
  Widget build(BuildContext context) {
    final memberInfoAsync = ref.watch(memberInfoProvider);
    final addressOverride = ref.watch(addressOverrideProvider);

    return Scaffold(
      appBar: NurimPageHeader(
        title: '내 정보 관리',
        onBackPressed: () => context.pop(),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: memberInfoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '회원정보를 불러오지 못했습니다.\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(memberInfoProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (memberInfo) {
            // 생년월일은 표시 전용(수정 불가) — 기획서 USR_MYP_010
            final displayBirthDate = _formatApiBirthDate(memberInfo.birthDate);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '기본 정보',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.66,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  _CustomInfoRow(
                                    title: '계정',
                                    infoText: memberInfo.email,
                                    subText: memberInfo.snsFlatform?.toUpperCase() == 'NAVER'
                                        ? '(네이버)'
                                        : memberInfo.snsFlatform?.toUpperCase() == 'KAKAO'
                                            ? '(카카오)'
                                            : '',
                                  ),
                                  _CustomInfoRow(
                                    title: '이름',
                                    infoText: memberInfo.name,
                                  ),
                                  _CustomInfoRow(
                                    title: '생년월일',
                                    infoText: displayBirthDate,
                                  ),
                                  _CustomInfoRow(
                                    title: '휴대폰 번호',
                                    infoText: _formatPhoneNumber(memberInfo.phoneNumber),
                                    showDivider: false,
                                    showChevron: true,
                                    onPressed: () {
                                      _changePhone(memberInfo.phoneNumber);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 6,
                        color: AppColors.bgGray,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '주소 정보',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.66,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            NurimAddressCard(
                              title: '현재 주소',
                              address: addressOverride ??
                                  (memberInfo.address.isNotEmpty
                                      ? memberInfo.address
                                      : '주소를 등록해 주세요.'),
                              onPressed: () async {
                                final result = await context.push<Map<String, dynamic>>(AppRoutes.addressWebView);
                                if (result != null && mounted) {
                                  final baseAddress = result['address'] as String? ?? '';
                                  final zipCode = result['zonecode'] as String? ?? '';
                                  if (baseAddress.isNotEmpty) {
                                    _showDetailAddressInputBottomSheet(memberInfo, baseAddress, zipCode);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 로그아웃·회원탈퇴는 화면 하단 고정
                // (피그마 196:7218 Account button — x16, 인디케이터 위 16)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton(
                        onPressed: _showLogoutDialog,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textMuted,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.66,
                          ),
                        ),
                        child: const Text('로그아웃'),
                      ),
                      // 피그마는 로그아웃 아래 24, 회원탈퇴 텍스트 아래 16.
                      // TextButton 기본 최소 높이(48)가 텍스트 위아래로 여백을
                      // 더 만들어 실측 41.7 / 34 가 나오므로, 탭 영역은 남기되
                      // 버튼 자체 패딩(8)만큼 바깥 간격에서 빼서 디자인에 맞춘다.
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push(AppRoutes.myWithdraw),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.66,
                            ),
                          ),
                          child: const Text('회원탈퇴'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 생년월일 포맷팅 헬퍼: "20100307" -> "2010년 3월 7일"
  String _formatApiBirthDate(String apiStr) {
    if (apiStr.length == 8) {
      final y = apiStr.substring(0, 4);
      final m = int.parse(apiStr.substring(4, 6)).toString();
      final d = int.parse(apiStr.substring(6, 8)).toString();
      return "$y년 $m월 $d일";
    }
    return apiStr.isNotEmpty ? apiStr : '2010년 3월 7일';
  }

  // 휴대폰 번호 포맷팅 헬퍼: "01012345678" -> "010-1234-5678"
  String _formatPhoneNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11) {
      return '${clean.substring(0, 3)}-${clean.substring(3, 7)}-${clean.substring(7)}';
    } else if (clean.length == 10) {
      return '${clean.substring(0, 3)}-${clean.substring(3, 6)}-${clean.substring(6)}';
    }
    return phone.isNotEmpty ? phone : '010-1234-1234';
  }

  // 로그아웃 확인 팝업 (공용 EdgeButtonDialog 사용)
  Future<void> _showLogoutDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '로그아웃하시겠어요?',
        content: '현재 계정에서 로그아웃됩니다.',
        cancelText: '취소',
        confirmText: '확인',
        onConfirm: _logout,
      ),
    );
  }

  /// 서버 로그아웃(best-effort) → 로컬 토큰 삭제 → 로그인 화면으로 이동
  Future<void> _logout() async {
    try {
      await ref
          .read(authRepositoryProvider)
          .logout()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // 서버 로그아웃 실패/지연 시에도 로컬 로그아웃은 계속 진행 (best-effort)
    }
    await ref.read(tokenStorageProvider).clearTokens();
    ref.invalidate(appBootstrapStateProvider);
    if (mounted) {
      context.go(AppRoutes.authStart);
    }
  }

  /// 휴대폰 번호 변경 흐름:
  /// 안내 바텀시트 → 본인인증(KCP, 새 번호 입력·인증) → 변경 확정 →
  /// memberInfoProvider 재조회로 새 번호 반영 → 성공 다이얼로그.
  Future<void> _changePhone(String currentPhone) async {
    if (_isChangingPhone) return;
    _isChangingPhone = true;
    try {
      // 1) 안내 바텀시트 (본인인증 필요 안내 + 현재 번호)
      final proceed = await _showPhoneChangeIntro(currentPhone);
      if (!mounted || !proceed) return;

      // 2) 본인인증(KCP) 거래 등록 요청 (purposeCode=CHANGE_PHONE)
      final repo = ref.read(memberRepositoryProvider);
      final req = await repo.requestPhoneChangeVerification();
      if (!mounted) return;
      if (req.webViewUrl.isEmpty) {
        ToastUtil.show(context, '본인인증 정보를 받지 못했습니다.');
        return;
      }

      // 3) KCP 본인인증 WebView (여기서 새 번호 입력·인증, 완료 시 true)
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => KcpCertWebViewScreen(webViewUrl: req.webViewUrl),
        ),
      );
      if (!mounted || verified != true) return;

      // 4) 변경 확정 + 재조회 (진행 중 블로킹 로딩)
      _showBlockingLoading();
      String newPhone;
      try {
        await repo.changePhone(requestToken: req.requestToken);
        ref.invalidate(memberInfoProvider);
        // 재조회로 새 번호 확보(+ 화면도 자동 갱신)
        final updated = await ref.read(memberInfoProvider.future);
        newPhone = updated.phoneNumber;
      } finally {
        if (mounted) Navigator.of(context).pop(); // 로딩 닫기
      }
      if (!mounted) return;

      // 5) 성공 다이얼로그(새 번호 표시). 화면 번호는 이미 갱신됨.
      await _showPhoneChangedDialog(newPhone);
    } catch (e) {
      if (mounted) {
        ToastUtil.show(context, '휴대폰 번호 변경 중 오류가 발생했습니다: $e');
      }
    } finally {
      _isChangingPhone = false;
    }
  }

  /// 휴대폰 변경 안내 바텀시트. [본인인증하기] 시 true 반환.
  Future<bool> _showPhoneChangeIntro(String currentPhone) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '휴대폰 번호 변경',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '휴대폰 번호 변경을 위해 본인인증이 필요해요.\n인증 화면에서 새 번호를 입력·인증하면 변경돼요.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bgGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '현재 번호',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textTertiary),
                      ),
                      const Spacer(),
                      Text(
                        _formatPhoneNumber(currentPhone),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('본인인증하기'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }

  /// 변경 진행 중 블로킹 로딩(수동 pop).
  void _showBlockingLoading() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }

  /// 휴대폰 번호 변경 성공 다이얼로그(Figma 186:5328 — 확인 1개, 꽉 찬 버튼).
  Future<void> _showPhoneChangedDialog(String newPhone) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => EdgeButtonDialog(
        title: '휴대폰 번호가\n변경되었습니다.',
        content: _formatPhoneNumber(newPhone),
        confirmText: '확인',
        onConfirm: () {},
      ),
    );
  }

  Future<void> _showDetailAddressInputBottomSheet(MemberInfo memberInfo, String baseAddress, String zipCode) async {
    final controller = TextEditingController();
    
    final detailAddress = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 검수 11행: 이 팝업은 뒤로가기가 아니라 X 로 닫는다(디자이너 요청)
                PopupHeader(
                  title: '주소 설정',
                  showBackButton: false,
                  onClosePressed: () => Navigator.pop(context),
                ),
                // 키보드가 올라와도 확인 버튼이 잘리지 않도록 본문만 줄어들고 스크롤된다
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 피그마 Content(196:7569): 헤더 아래 16, 블록 간 24
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 피그마 Address lnfo(196:6919)
                              Text(
                                baseAddress,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                  letterSpacing: -0.66,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    height: 24,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '도로명',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                        letterSpacing: -0.66,
                                        // 피그마 leading 1.4 를 그대로 주면 줄상자(18.2)가
                                        // 컨텐츠 박스(24-4-4=16)를 넘겨 글자가 아래로
                                        // 3.67 쏠린다. 폰트 고유 줄높이를 명시해 맞춘다.
                                        // (Pretendard ascent+descent = 14/12 em, 크기 무관)
                                        height: 14 / 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      baseAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                        letterSpacing: -0.66,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 피그마 Line6(196:7001) — 시트 폭 전체를 가로지르는 6 구분 바.
                        // 예전엔 좌우 패딩 안에서 음수 마진으로 흉내내다 디버그 빌드에서
                        // Container assert(margin.isNonNegative)로 시트가 죽었다.
                        Container(height: 6, color: AppColors.bgGray),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 피그마 Detail address(196:7054)
                              const Text(
                                '상세 주소를 입력해 주세요.',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textStrong,
                                  height: 1.4,
                                  letterSpacing: -0.66,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: controller,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: '상세 주소 입력',
                                  hintStyle: const TextStyle(
                                    color: AppColors.placeholder,
                                  ),
                                  // 피그마 Input field base(196:6987): 높이 52, radius 12
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                // 피그마 Navi button(200:4631): 좌우 16, 위 4.
                // 피그마는 버튼 하단이 iOS 홈 인디케이터(34, 흰 여백)에 바로 붙지만,
                // Android 는 그 자리가 검은 내비게이션 바라 붙으면 답답해 보인다.
                // 같은 파일 Account button(196:7218)이 쓰는 16 을 안전영역 위에 둔다.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: ElevatedButton(
                    onPressed: () {
                      final detail = controller.text.trim();
                      Navigator.pop(context, detail);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      // 피그마 Navi button: h56, radius 12, 18 SemiBold
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.66,
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (detailAddress != null && mounted) {
      final finalCombinedAddress = detailAddress.isEmpty ? baseAddress : '$baseAddress $detailAddress';
      
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    '주소가 저장되었습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (confirm == true && mounted) {
        try {
          await ref.read(memberRepositoryProvider).updateMemberAddress(
            zipCode: zipCode,
            address1: baseAddress,
            address2: detailAddress,
          );
          
          ref.read(addressOverrideProvider.notifier).updateAddress(finalCombinedAddress);
          
          ref.invalidate(memberInfoProvider);
          ref.invalidate(memberMyPageProvider);
        } catch (e) {
          if (mounted) {
            ToastUtil.show(context, '주소 저장 중 오류가 발생했습니다: $e');
          }
        }
      }
    }
  }
}

class _CustomInfoRow extends StatelessWidget {
  const _CustomInfoRow({
    required this.title,
    required this.infoText,
    this.subText,
    this.showDivider = true,
    this.showChevron = false,
    this.onPressed,
  });

  final String title;
  final String infoText;
  final String? subText;
  final bool showDivider;
  final bool showChevron;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: -0.66,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    infoText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
                if (subText != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    subText!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.66,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 2),
            // Figma Icon/ArrowRight/16
            SvgPicture.asset(
              'assets/images/ic_arrow_right_16.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                AppColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ],
        ],
      ),
    );

    if (onPressed != null) {
      child = InkWell(
        onTap: onPressed,
        child: child,
      );
    }
    if (!showDivider) return child;

    // 피그마 Info base(196:7226)는 카드에 좌우 패딩 16 을 줘서 행 폭이 311 이고,
    // 구분선(행의 하단 보더)이 카드 좌우 끝에 닿지 않는다. 행 폭은 그대로 두고
    // 선만 16 들여쓴다. 보더를 걷어낸 만큼(1) 선 높이가 대신하므로 행 높이는 그대로다.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.borderLight,
        ),
      ],
    );
  }
}

