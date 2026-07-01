import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../app/app_routes.dart';
import '../../../core/widgets/list_button.dart';
import '../../../core/widgets/my_info_row.dart';
import '../../../core/widgets/mypage_name.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/pet_card.dart';
import '../../../core/widgets/section_title.dart';
import '../data/member_repository.dart';
import '../domain/member_my_page.dart';
import 'my_pet_list_screen.dart';

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
    final petsState = ref.watch(myPetsListProvider);

    return myPageState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _MyPageErrorView(
        message: '마이페이지 정보를 불러오지 못했습니다.',
        onRetry: () => ref.invalidate(memberMyPageProvider),
      ),
      data: (myPage) => petsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _MyPageErrorView(
          message: '마이페이지 정보를 불러오지 못했습니다.',
          onRetry: () {
            ref.invalidate(memberMyPageProvider);
            ref.invalidate(myPetsListProvider);
          },
        ),
        data: (serverPets) {
          final mappedPets = serverPets.map((item) {
            final imageUrl = item.profileFileId != null
                ? ref.read(apiClientProvider).uri('/api/v1/files/${item.profileFileId}').toString()
                : null;

            return NurimPetCardData(
              name: item.petName,
              breed: item.breedNameKor ?? '믹스',
              ageText: '${item.petAge}살',
              genderText: item.genderCodeNm ?? (item.genderCode == 'MALE' ? '남아' : '여아'),
              membershipTier: item.representYn == 'Y' ? '브론즈' : '멤버십 가입하기',
              rewardText: '28,000P',
              isPrimary: item.representYn == 'Y',
              imageProvider: imageUrl != null ? NetworkImage(imageUrl) : null,
            );
          }).toList();

          return _MyPageContent(
            myPage: myPage,
            pets: mappedPets,
            isLoggingOut: isLoggingOut,
            onLogout: onLogout,
            onBackToHome: onBackToHome,
          );
        },
      ),
    );
  }
}

class _MyPageContent extends StatefulWidget {
  const _MyPageContent({
    required this.myPage,
    required this.pets,
    required this.isLoggingOut,
    required this.onLogout,
    this.onBackToHome,
  });

  final MemberMyPage myPage;
  final List<NurimPetCardData> pets;
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

    final pets = widget.pets;

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
                        labelText: '내 정보 관리',
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
              NurimSectionTitle(
                title: '마이 펫',
                actionLabel: '전체보기',
                showAction: pets.length >= 2,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                onActionPressed: () => context.push(AppRoutes.myPetList),
              ),
              const SizedBox(height: 12),

              // 마이 펫 카드 리스트 (NurimMyPetSection)
              // (상위 패딩 20px이 리스트뷰에 적용되도록 padding 인자 전달)
              NurimMyPetSection(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                pets: pets,
                onPetPressed: (_) {},
                onAddPressed: () => context.push(AppRoutes.myPetAdd),
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
                onPressed: () => context.push(AppRoutes.customerCenter),
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

