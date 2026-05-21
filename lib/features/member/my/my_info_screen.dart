import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_bootstrap.dart';
import '../../../app/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../data/member_repository.dart';

class MyInfoScreen extends ConsumerStatefulWidget {
  const MyInfoScreen({super.key});

  @override
  ConsumerState<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends ConsumerState<MyInfoScreen> {
  String? _customBirthDate; // 사용자가 휠 피커로 변경한 생년월일(목업)

  @override
  Widget build(BuildContext context) {
    final memberInfoAsync = ref.watch(memberInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '나의 정보',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: '뒤로',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                _ProfileHeader(name: memberInfo.name),
                const SizedBox(height: 28),
                _InfoRow(
                  label: '연결계정',
                  value: memberInfo.email,
                  // 연결계정은 변경이 불가능하므로 action(변경 버튼)을 제공하지 않습니다.
                ),
                _InfoRow(
                  label: '휴대폰 번호',
                  value: _formatPhoneNumber(memberInfo.phoneNumber),
                  action: '변경',
                  onActionPressed: () {
                    // 본인인증(공통) 진행 안내 목업
                    _showMockDialog('휴대폰 번호 변경', '휴대폰 번호 변경을 위해 본인인증을 진행합니다.');
                  },
                ),
                _InfoRow(
                  label: '비밀번호',
                  value: '',
                  action: '변경',
                  onActionPressed: () {
                    // 비밀번호 변경 본인인증 안내 목업
                    _showMockDialog('비밀번호 변경', '비밀번호 변경을 위해 본인인증을 진행합니다.');
                  },
                ),
                _InfoRow(
                  label: '주소',
                  value: memberInfo.address.isNotEmpty
                      ? memberInfo.address
                      : '등록된 주소가 없습니다.',
                  action: '변경',
                  onActionPressed: () {
                    // 주소 변경 (주소 WebView 화면 이동 등)
                    context.push(AppRoutes.addressWebView);
                  },
                ),
                _InfoRow(
                  label: '생년월일',
                  value: displayBirthDate,
                  action: '변경',
                  onActionPressed: () => _showBirthDatePicker(memberInfo.birthDate),
                ),
                
                // 로그아웃 Row (디자인 가이드에 따라 리스트 타일 형태로 탭 시 다이얼로그 호출)
                InkWell(
                  onTap: _showLogoutDialog,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '로그아웃',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                
                // 회원탈퇴 Row
                InkWell(
                  onTap: () => context.push(AppRoutes.myWithdraw),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '회원탈퇴',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
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
  void _showBirthDatePicker(String apiBirthDate) {
    DateTime initialDate = DateTime(2010, 3, 7);
    if (_customBirthDate != null) {
      initialDate = _parseDisplayBirthDate(_customBirthDate!);
    } else if (apiBirthDate.length == 8) {
      initialDate = _parseApiBirthDate(apiBirthDate);
    }

    DateTime selectedDate = initialDate;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          height: 320,
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '생년월일',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _customBirthDate =
                              "${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일";
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.light,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    maximumDate: DateTime.now(),
                    minimumYear: 1900,
                    maximumYear: DateTime.now().year,
                    onDateTimeChanged: (date) {
                      selectedDate = date;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  children: [
                    Text(
                      '로그아웃 안내',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '진행 중인 서비스가 있는 상태에서 로그아웃할 경우 안내를 받을 수 없습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.grey),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 48, color: Colors.grey),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ),
                      child: const Text(
                        '로그아웃',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout == true) {
      await ref.read(tokenStorageProvider).clearAccessToken();
      ref.invalidate(appBootstrapStateProvider);
      if (mounted) {
        context.go(AppRoutes.authStart);
      }
    }
  }

  // 변경 안내 목업 다이얼로그
  void _showMockDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          content: Text(message, style: const TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : '홍길동';
    return Column(
      children: [
        const CircleAvatar(
          radius: 36,
          backgroundColor: Color(0xFFE5E7EB),
          child: Icon(Icons.person, size: 40, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Text(
          '$displayName 님',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.action,
    this.onActionPressed,
  });

  final String label;
  final String value;
  final String? action;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onActionPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                    minimumSize: const Size(56, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    action!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
