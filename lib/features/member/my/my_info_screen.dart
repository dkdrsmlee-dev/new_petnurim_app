import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_bootstrap.dart';
import '../../../app/app_routes.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/member_repository.dart';

class MyInfoScreen extends ConsumerStatefulWidget {
  const MyInfoScreen({super.key});

  @override
  ConsumerState<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends ConsumerState<MyInfoScreen> {
  bool _isWithdrawing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 정보'),
        leading: IconButton(
          tooltip: '뒤로',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            const _ProfileHeader(),
            const SizedBox(height: 28),
            const _InfoRow(
              label: '연결계정',
              value: 'email@email.co.kr',
              action: '변경',
            ),
            const _InfoRow(label: '휴대폰 번호', value: '010-1234-1234'),
            const _InfoRow(label: '비밀번호', value: '', action: '변경'),
            const _InfoRow(
              label: '주소',
              value: '서울시 강남구 역삼동 123-45 12층\n오크빌 1204호',
              action: '변경',
            ),
            const _InfoRow(label: '생년월일', value: '2010년 3월 7일', action: '변경'),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '로그아웃',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              value: false,
              onChanged: (_) {},
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '회원탈퇴',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _isWithdrawing ? null : _confirmWithdraw,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(72, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: _isWithdrawing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('회원탈퇴'),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmWithdraw() async {
    final shouldWithdraw = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('회원탈퇴'),
          content: const Text('회원탈퇴를 진행하면 현재 계정으로 앱을 계속 사용할 수 없습니다. 탈퇴하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('탈퇴하기'),
            ),
          ],
        );
      },
    );

    if (shouldWithdraw == true) {
      await _withdraw();
    }
  }

  Future<void> _withdraw() async {
    setState(() {
      _isWithdrawing = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(memberRepositoryProvider)
          .withdraw(reasonCode: 'ETC', reasonText: '앱에서 회원탈퇴 요청');
      await ref.read(tokenStorageProvider).clearAccessToken();
      ref.invalidate(appBootstrapStateProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회원탈퇴가 처리되었습니다.')));
      context.go(AppRoutes.authStart);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _readErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });
      }
    }
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException) {
      return error.toString();
    }

    return error.toString();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(radius: 36, backgroundColor: Color(0xFFE5E7EB)),
        SizedBox(height: 12),
        Text('홍길동 님', style: TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.action});

  final String label;
  final String value;
  final String? action;

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
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(height: 1.35),
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(56, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(action!),
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
