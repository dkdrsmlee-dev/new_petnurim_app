import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/list_button.dart';
import '../../../core/widgets/my_info_row.dart';
import '../../../core/widgets/mypage_name.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';
import '../../../core/widgets/section_title.dart';
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
        // 1. 고정 상단 헤더
        NurimPageHeader(
          title: '마이 페이지',
          onBackPressed: widget.onBackToHome,
        ),
        // 2. 본문 스크롤 영역
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: NurimMypageName(name: name),
              ),
              const SizedBox(height: 16),

              // My_info 통합 카드 (내 정보 + 결제 수단)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DecoratedBox(
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
              ),
              const SizedBox(height: 24),

              // 구분선 (Section Divider) - 화면 전체 너비
              Container(
                height: 8,
                color: const Color(0xFFF4F6F8), // var(--color/gray/20, #f4f6f8)
              ),
              const SizedBox(height: 24),

              // 마이 펫 타이틀 영역 (NurimSectionTitle)
              const NurimSectionTitle(
                title: '마이 펫',
                actionLabel: '전체보기',
                showAction: true,
                padding: EdgeInsets.symmetric(horizontal: 20),
              ),
              const SizedBox(height: 12),

              // 마이 펫 카드 리스트 (NurimMyPetSection)
              // (상위 패딩 20px이 리스트뷰에 적용되도록 padding 인자 전달)
              NurimMyPetSection(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
              const SizedBox(height: 24),

              // 구분선 (Section Divider) - 화면 전체 너비
              Container(
                height: 8,
                color: const Color(0xFFF4F6F8), // var(--color/gray/20, #f4f6f8)
              ),

              // 하단 메뉴 목록 영역 (고객센터, 서비스 약관, 설정)
              NurimListButton(
                title: '고객센터',
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                onPressed: () {},
              ),
              NurimListButton(
                title: '서비스 약관',
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                onPressed: () {},
              ),
              NurimListButton(
                title: '설정',
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                onPressed: () {},
              ),
              const SizedBox(height: 24),

              // 로그아웃 버튼 (테스트 유지를 위해 하단에 배치)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SurfacePanel(
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
              ),

            ],
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
