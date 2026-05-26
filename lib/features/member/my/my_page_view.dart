import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/membership_card.dart';
import '../../../core/widgets/my_info_row.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';
import '../data/member_repository.dart';
import '../domain/member_my_page.dart';

class MyPageView extends ConsumerWidget {
  const MyPageView({
    super.key,
    required this.isLoggingOut,
    required this.onLogout,
    this.onBackToHome,
  });

  final bool isLoggingOut;
  final VoidCallback onLogout;
  final VoidCallback? onBackToHome;

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
        onBackToHome: onBackToHome,
      ),
    );
  }
}

class _MyPageContent extends StatefulWidget {
  const _MyPageContent({
    required this.myPage,
    required this.isLoggingOut,
    required this.onLogout,
    this.onBackToHome,
  });

  final MemberMyPage myPage;
  final bool isLoggingOut;
  final VoidCallback onLogout;
  final VoidCallback? onBackToHome;

  @override
  State<_MyPageContent> createState() => _MyPageContentState();
}

class _MyPageContentState extends State<_MyPageContent> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.myPage.name.isNotEmpty ? widget.myPage.name : '홍길동';
    final email = widget.myPage.email.isNotEmpty
        ? widget.myPage.email
        : 'example@example.com';

    return Column(
      children: [
        NurimPageHeader(
          title: '마이 페이지',
          onBackPressed: widget.onBackToHome,
        ),
        Expanded(
          child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        // Mypage name (Profile header)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20, // 40px diameter
                backgroundColor: const Color(0xFF7F4FFF), // var(--color/violet/90, #7f4fff)
                child: Text(
                  name.isNotEmpty ? name[0] : '홍',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$name님 반가워요 :)',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 18,
                  fontWeight: FontWeight.w600, // SemiBold
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: Color(0xFF30343C), // strong text color
                ),
              ),
            ],
          ),
        ),
        // My_info 통합 카드
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD6DBE4)), // var(--line/default, #d6dbe4)
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NurimMyInfoRow(
                labelText: '내 정보',
                primaryValue: email,
                secondaryValue: '(카카오)',
                actionLabel: '관리',
                onActionPressed: () => context.push(AppRoutes.myInfo),
                showDivider: true,
              ),
              NurimMyInfoRow(
                labelText: '결제 수단',
                primaryValue: email,
                secondaryValue: '삼성카드(12**)',
                actionLabel: '변경',
                onActionPressed: () {},
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _MembershipCardSlider(),
        const SizedBox(height: 12),
        NurimMyPetSection(
          padding: EdgeInsets.zero,
          pets: [
            const NurimPetCardData(
              name: '콩두리',
              breed: '웰시코기',
              ageText: '2살',
              genderText: '남아',
              membershipTier: '브론즈',
              rewardText: '28,000P',
              isPrimary: true,
              imageProvider: NetworkImage(
                'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=150&h=150&fit=crop',
              ),
            ),
            const NurimPetCardData(
              name: '초코',
              breed: '푸들',
              ageText: '3살',
              genderText: '여아',
              membershipTier: '실버',
              rewardText: '15,000P',
              isPrimary: false,
              imageProvider: NetworkImage(
                'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=150&h=150&fit=crop',
              ),
            ),
          ],
          onPetPressed: (_) {},
          onAddPressed: () {},
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
            onPressed: widget.isLoggingOut ? null : widget.onLogout,
            icon: widget.isLoggingOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(widget.isLoggingOut ? '로그아웃 중' : '로그아웃'),
          ),
        ),
      ],
    ),
  ),
],
);
  }
}

// ── 멤버십 카드 슬라이더 ────────────────────────────────────────────
class _MembershipCardSlider extends StatefulWidget {
  const _MembershipCardSlider();

  @override
  State<_MembershipCardSlider> createState() => _MembershipCardSliderState();
}

class _MembershipCardSliderState extends State<_MembershipCardSlider> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<_MembershipCardData> _cards = [
    _MembershipCardData(
      tierName: '브론즈',
      nextBillingDate: '2026.05.12',
      monthlyFee: '10,000원',
      statusLabel: '현재 이용 중',
      badgeColor: Color(0xFFCD7F32),
    ),
    _MembershipCardData(
      tierName: '실버',
      nextBillingDate: '-',
      monthlyFee: '15,000원',
      statusLabel: '업그레이드 가능',
      badgeColor: Color(0xFFAAAAAA),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // viewportFraction < 1 이면 양쪽 카드가 살짝 보임
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 섹션 타이틀 행 ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '멤버십',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF30343C),
                    letterSpacing: -0.66,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Text(
                      '전체보기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF87909E),
                        letterSpacing: -0.66,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF87909E),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── PageView 카드 캐러셀 ─────────────────────────────────
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _cards.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) {
              final card = _cards[index];
              return Padding(
                // 카드 사이 간격
                padding: EdgeInsets.only(
                  right: index < _cards.length - 1 ? 12 : 0,
                ),
                child: NurimMembershipCard(
                  tierName: card.tierName,
                  nextBillingDate: card.nextBillingDate,
                  monthlyFee: card.monthlyFee,
                  statusLabel: card.statusLabel,
                  onBenefitTapped: () {},
                  onPaymentHistoryTapped: () {},
                ),
              );
            },
          ),
        ),
        // ── 페이지 인디케이터 ─────────────────────────────────────
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _cards.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentPage ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? const Color(0xFF7F4FFF)
                    : const Color(0xFFD6DBE4),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MembershipCardData {
  const _MembershipCardData({
    required this.tierName,
    required this.nextBillingDate,
    required this.monthlyFee,
    required this.statusLabel,
    required this.badgeColor,
  });

  final String tierName;
  final String nextBillingDate;
  final String monthlyFee;
  final String statusLabel;
  final Color badgeColor;
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
