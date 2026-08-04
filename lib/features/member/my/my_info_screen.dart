import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_bootstrap.dart';
import '../../../app/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/address_card.dart';
import '../../../core/widgets/nurim_date_picker.dart';
import '../../../core/widgets/page_header.dart';
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
  String? _customBirthDate; // 사용자가 휠 피커로 변경한 생년월일(목업)
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
            // API 생년월일 포맷팅
            final formattedApiBirthDate = _formatApiBirthDate(memberInfo.birthDate);
            final displayBirthDate = _customBirthDate ?? formattedApiBirthDate;

            return ListView(
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
                              onPressed: () => _showBirthDatePicker(memberInfo.birthDate),
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
                      const SizedBox(height: 50),
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
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push(AppRoutes.myWithdraw),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
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

  // CupertinoDatePicker Bottom Sheet (Wheel Picker 방식)
  Future<void> _showBirthDatePicker(String apiBirthDate) async {
    DateTime initialDate = DateTime(2010, 3, 7);
    if (_customBirthDate != null) {
      initialDate = _parseDisplayBirthDate(_customBirthDate!);
    } else if (apiBirthDate.length == 8) {
      initialDate = _parseApiBirthDate(apiBirthDate);
    }

    final selected = await NurimDatePickerBottomSheet.show(
      context: context,
      title: '생년월일',
      initialDate: initialDate,
      minimumDate: DateTime(1900),
      maximumDate: DateTime.now(),
    );

    if (selected != null && mounted) {
      setState(() {
        _customBirthDate =
            "${selected.year}년 ${selected.month}월 ${selected.day}일";
      });
    }
  }

  DateTime _parseDisplayBirthDate(String displayStr) {
    try {
      final clean = displayStr
          .replaceAll('년', '')
          .replaceAll('월', '')
          .replaceAll('일', '');
      final parts = clean.split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 3) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return DateTime(2010, 3, 7);
  }

  DateTime _parseApiBirthDate(String apiStr) {
    try {
      if (apiStr.length == 8) {
        final y = int.parse(apiStr.substring(0, 4));
        final m = int.parse(apiStr.substring(4, 6));
        final d = int.parse(apiStr.substring(6, 8));
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return DateTime(2010, 3, 7);
  }

  // 로그아웃 확인 팝업 (기획서 디자인에 맞춘 커스텀 다이얼로그)
  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '로그아웃하시겠어요?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(false),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '현재 계정에서 로그아웃됩니다.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout == true) {
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

  /// 휴대폰 번호 변경 성공 다이얼로그(확인 1개).
  Future<void> _showPhoneChangedDialog(String newPhone) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                const Text(
                  '휴대폰 번호가 변경되었어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatPhoneNumber(newPhone),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
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
                ),
              ],
            ),
          ),
        );
      },
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
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF1E2024)),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          '주소 설정',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2024),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  baseAddress,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '도로명',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B66FF),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '상세 주소를 입력해 주세요.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '상세 주소 입력',
                    hintStyle: const TextStyle(color: AppColors.placeholder),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    final detail = controller.text.trim();
                    Navigator.pop(context, detail);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(52),
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
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: AppColors.borderLight),
              )
            : null,
      ),
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
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
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
    return child;
  }
}

