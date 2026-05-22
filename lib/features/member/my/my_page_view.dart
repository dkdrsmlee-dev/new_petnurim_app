import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../data/member_repository.dart';
import '../domain/member_my_page.dart';

class MyPageView extends ConsumerWidget {
  const MyPageView({
    super.key,
    required this.isLoggingOut,
    required this.onLogout,
  });

  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPageState = ref.watch(memberMyPageProvider);

    return myPageState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _MyPageErrorView(
        message: '마이페이지 정보를 불러오지 못했습니다.',
        onRetry: () => ref.invalidate(memberMyPageProvider),
      ),
      data: (myPage) => _MyPageContent(
        myPage: myPage,
        isLoggingOut: isLoggingOut,
        onLogout: onLogout,
      ),
    );
  }
}

class _MyPageContent extends StatelessWidget {
  const _MyPageContent({
    required this.myPage,
    required this.isLoggingOut,
    required this.onLogout,
  });

  final MemberMyPage myPage;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = myPage.name.isNotEmpty ? myPage.name : '홍길동';
    final email = myPage.email.isNotEmpty
        ? myPage.email
        : 'example@example.com';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '$name님의 정보를 관리하실 수 있습니다.',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        _SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '나의 정보',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.myInfo),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(92, 36),
                    ),
                    child: const Text('정보 수정'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(email),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _SurfacePanel(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('멤버십', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('월 3.0 멤버십 (2026/04/12 가입)'),
                  ],
                ),
              ),
              SizedBox(width: 10),
              _SmallOutlinedButton(label: '정보 수정'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _SurfacePanel(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('마이 펫', style: TextStyle(fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('똘똘이 2살/남'),
                  ],
                ),
              ),
              SizedBox(width: 10),
              _SmallOutlinedButton(label: '정보 수정'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _ListButton(
          icon: Icons.stars_outlined,
          title: '리워드 관리',
          subtitle: '보유중인 리워드 총액 45,000 Point',
        ),
        const SizedBox(height: 10),
        const _ListButton(
          icon: Icons.credit_card_outlined,
          title: '결제수단 관리',
          subtitle: '월 3.0결제용(**12)',
        ),
        const SizedBox(height: 10),
        const _ListButton(
          icon: Icons.support_agent,
          title: '고객센터',
          subtitle: '',
        ),
        const SizedBox(height: 10),
        const _ListButton(
          icon: Icons.description_outlined,
          title: '서비스 약관',
          subtitle: '',
        ),
        const SizedBox(height: 10),
        const _ListButton(
          icon: Icons.settings_outlined,
          title: '설정',
          subtitle: '',
        ),
        const SizedBox(height: 16),
        _SurfacePanel(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: isLoggingOut ? null : onLogout,
            icon: isLoggingOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(isLoggingOut ? '로그아웃 중' : '로그아웃'),
          ),
        ),
      ],
    );
  }
}

class _MyPageErrorView extends StatelessWidget {
  const _MyPageErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _ListButton extends StatelessWidget {
  const _ListButton({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: subtitle.isEmpty ? 16 : 14,
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _SmallOutlinedButton extends StatelessWidget {
  const _SmallOutlinedButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(92, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(label),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
