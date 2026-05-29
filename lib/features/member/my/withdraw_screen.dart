import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_bootstrap.dart';
import '../../../app/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/member_repository.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  // 탈퇴 사유 목록
  final List<String> _reasons = [
    '사용 빈도가 낮음',
    '원하는 기능/서비스가 없음',
    '서비스 이용이 불편해서',
    '가격(비용)이 부담됨',
    '개인정보/보안 우려',
    '고객 응대가 불만족스러움',
    '기타 (직접 입력)',
  ];

  // 사유 코드 매핑 (백엔드 WITHDRAW_REASON_TYPE 일치)
  final Map<int, String> _reasonCodes = {
    0: 'LOW_USAGE',
    1: 'FEATURE_LACK',
    2: 'INCONVENIENT',
    3: 'PRICE',
    4: 'PRIVACY',
    5: 'CUSTOMER_SERVICE',
    6: 'ETC',
  };

  int? _selectedReasonIndex; // 선택된 사유 인덱스
  final TextEditingController _customReasonController = TextEditingController();
  bool _agreed = false; // 동의 여부 체크박스 상태
  bool _isWithdrawing = false; // 탈퇴 로딩 상태
  String? _errorMessage;

  // 데모/테스트용: 사용자가 '구독 중인 서비스 예외 팝업'도 테스트할 수 있도록 하는 플래그
  bool _mockIsSubscribed = false;

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '회원탈퇴',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          // 테스트용 구독 플래그 스위치
          if (kDebugMode)
            Row(
              children: [
                const Text(
                  '구독상태(테스트)',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
                Switch(
                  value: _mockIsSubscribed,
                  activeThumbColor: Colors.black,
                  onChanged: (val) {
                    setState(() {
                      _mockIsSubscribed = val;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // 1. 유의사항 안내 섹션
                  const Text(
                    '회원탈퇴 전에 꼭 확인해 주세요.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BulletItem(text: '탈퇴 시 계정 및 데이터는 복구되지 않습니다.'),
                        SizedBox(height: 8),
                        _BulletItem(text: '보유 중인 리워드/포인트는 모두 소멸됩니다.'),
                        SizedBox(height: 8),
                        _BulletItem(
                            text: '진행 중인 서비스/구독은 잔여 기간을 모두 소진한 후 탈퇴가능합니다.'),
                        SizedBox(height: 8),
                        _BulletItem(text: '탈퇴 후 30일 동안 재가입이 불가합니다.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. 탈퇴 사유 선택 섹션
                  const Text(
                    '회원탈퇴 사유를 선택 해 주세요.(선택)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_reasons.length, (index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedReasonIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              _selectedReasonIndex == index
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: _selectedReasonIndex == index
                                  ? Colors.black
                                  : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _reasons[index],
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // '기타 (직접 입력)' 선택 시 텍스트 영역 활성화
                  if (_selectedReasonIndex == 6) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customReasonController,
                      maxLines: 4,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: '탈퇴 사유를 입력해 주세요.',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // 3. 회원탈퇴 동의하기 섹션
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        '유의사항을 모두 확인하였으며, 회원 탈퇴에 동의 합니다.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      value: _agreed,
                      activeColor: Colors.black,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (value) {
                        setState(() {
                          _agreed = value ?? false;
                        });
                      },
                    ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _agreed && !_isWithdrawing ? _handleWithdrawClick : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isWithdrawing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          '회원탈퇴',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _agreed ? Colors.white : Colors.grey.shade500,
                          ),
                        ),
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
    if (_mockIsSubscribed) {
      // 1) 구독 중인 경우 예외 팝업 (USR-MIF-026)
      _showSubscriptionAlert();
    } else {
      // 2) 정상 탈퇴 확인 팝업 (USR-MIF-025)
      _showWithdrawConfirmAlert();
    }
  }

  // 1) 구독 중인 서비스 안내 팝업
  void _showSubscriptionAlert() {
    showDialog(
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
                      '구독 서비스 안내',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '4월 30일까지 구독중인 서비스가 있습니다.\n멤버십 해지 후 회원탈퇴를 진행해 주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 기획서: 멤버십 관리 페이지로 이동 혹은 그냥 팝업 닫음
                    // 여기서는 팝업을 닫고 이전 나의 정보 화면으로 복귀하거나 일단 닫기 처리
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2) 일반 탈퇴 진행 확인 팝업
  void _showWithdrawConfirmAlert() {
    showDialog(
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
                      '회원탈퇴',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '회원탈퇴를 진행하시겠습니까?\n탈퇴 시 계정 및 모든 데이터는 복구되지 않습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                      onPressed: () {
                        Navigator.of(context).pop();
                        _executeWithdraw();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ),
                      child: const Text(
                        '탈퇴하기',
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
  }

  // 실제 API를 통한 회원탈퇴 수행
  Future<void> _executeWithdraw() async {
    setState(() {
      _isWithdrawing = true;
      _errorMessage = null;
    });

    final reasonCode = _selectedReasonIndex != null
        ? _reasonCodes[_selectedReasonIndex!] ?? 'ETC'
        : 'ETC';

    // 기타 사유 텍스트 구성
    String reasonText = '앱에서 회원탈퇴 요청';
    if (_selectedReasonIndex == 6 && _customReasonController.text.trim().isNotEmpty) {
      reasonText = _customReasonController.text.trim();
    } else if (_selectedReasonIndex != null) {
      reasonText = _reasons[_selectedReasonIndex!];
    }

    try {
      await ref.read(memberRepositoryProvider).withdraw(
            reasonCode: reasonCode,
            reasonText: reasonText,
          );

      await ref.read(tokenStorageProvider).clearTokens();
      ref.invalidate(appBootstrapStateProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원탈퇴가 성공적으로 처리되었습니다.')),
      );
      
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 세션이 만료되었습니다. 다시 로그인해 주세요.')),
          );
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
class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
