import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _tabTitles = ['홈', '소식', '마이', '혜택', '이벤트'];
  static const _tabDescriptions = [
    '메인 배너, 공지, 추천 이벤트를 배치할 영역입니다.',
    '공지사항과 알림 피드를 연결할 영역입니다.',
    '회원 프로필과 설정 진입점을 배치할 영역입니다.',
    '쿠폰, 포인트, 제휴 혜택을 배치할 영역입니다.',
    '운영 이벤트와 캠페인을 노출할 영역입니다.',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('펫누림 홈'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: () => context.go(AppRoutes.authStart),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              _tabTitles[_selectedIndex],
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              _tabDescriptions[_selectedIndex],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2단계 홈 골격',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 10),
                    Text('하단 탭, 로그아웃 진입점, 홈 라우팅이 연결된 상태입니다.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: '소식',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: '혜택',
          ),
          NavigationDestination(
            icon: Icon(Icons.celebration_outlined),
            selectedIcon: Icon(Icons.celebration),
            label: '이벤트',
          ),
        ],
      ),
    );
  }
}
