import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_bootstrap.dart';
import '../../app/app_routes.dart';
import '../../core/storage/token_storage.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  static const _tabs = [
    _HomeTab(
      label: '홈',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      title: '펫누림 홈',
    ),
    _HomeTab(
      label: '진료',
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services,
      title: '진료',
    ),
    _HomeTab(
      label: '반려동물',
      icon: Icons.pets_outlined,
      selectedIcon: Icons.pets,
      title: '반려동물',
    ),
    _HomeTab(
      label: '마이',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      title: '마이페이지',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTab = _tabs[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTab.title),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: '알림',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            tooltip: '설정',
            onPressed: () => setState(() => _selectedIndex = 3),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _HomeOverview(onOpenCare: () => setState(() => _selectedIndex = 1)),
            const _CareTabView(),
            const _PetTabView(),
            _MyPageView(isLoggingOut: _isLoggingOut, onLogout: _logout),
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
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    await ref.read(tokenStorageProvider).clearAccessToken();
    ref.invalidate(appBootstrapStateProvider);

    if (!mounted) {
      return;
    }

    context.go(AppRoutes.authStart);
  }
}

class _HomeTab {
  const _HomeTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.title,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String title;
}

class _HomeOverview extends StatelessWidget {
  const _HomeOverview({required this.onOpenCare});

  final VoidCallback onOpenCare;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 펫누림',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '반려동물 관리와 진료 준비를 한곳에서 확인하세요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onOpenCare,
                icon: const Icon(Icons.event_available),
                label: const Text('진료 준비하기'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionTitle(title: '바로가기'),
        const SizedBox(height: 10),
        const _QuickActionGrid(),
        const SizedBox(height: 20),
        const _SectionTitle(title: '최근 알림'),
        const SizedBox(height: 10),
        const _NoticeList(),
      ],
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.7,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _ActionTile(icon: Icons.assignment_outlined, label: '문진표'),
        _ActionTile(icon: Icons.local_hospital_outlined, label: '병원 찾기'),
        _ActionTile(icon: Icons.vaccines_outlined, label: '접종 기록'),
        _ActionTile(icon: Icons.receipt_long_outlined, label: '진료 내역'),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeList extends StatelessWidget {
  const _NoticeList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _NoticeTile(title: '가입 정보가 안전하게 연결되었습니다.', date: '오늘'),
        SizedBox(height: 10),
        _NoticeTile(title: '반려동물 프로필을 등록해 주세요.', date: '대기'),
      ],
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.title, required this.date});

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return _SurfacePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          const SizedBox(width: 8),
          Text(
            date,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _CareTabView extends StatelessWidget {
  const _CareTabView();

  @override
  Widget build(BuildContext context) {
    return const _ListPage(
      title: '진료 관리',
      description: '예약, 문진, 진료 내역을 확인합니다.',
      items: [
        _ListItem(
          icon: Icons.event_note_outlined,
          title: '예약 일정',
          subtitle: '예정된 진료 일정',
        ),
        _ListItem(
          icon: Icons.edit_note_outlined,
          title: '문진 작성',
          subtitle: '방문 전 상태 기록',
        ),
        _ListItem(
          icon: Icons.history_outlined,
          title: '진료 내역',
          subtitle: '이전 진료 기록',
        ),
      ],
    );
  }
}

class _PetTabView extends StatelessWidget {
  const _PetTabView();

  @override
  Widget build(BuildContext context) {
    return const _ListPage(
      title: '반려동물',
      description: '반려동물 프로필과 건강 기록을 관리합니다.',
      items: [
        _ListItem(
          icon: Icons.add_circle_outline,
          title: '프로필 등록',
          subtitle: '이름, 품종, 생일',
        ),
        _ListItem(
          icon: Icons.monitor_heart_outlined,
          title: '건강 기록',
          subtitle: '체중과 주요 증상',
        ),
        _ListItem(
          icon: Icons.vaccines_outlined,
          title: '접종 관리',
          subtitle: '예방접종 기록',
        ),
      ],
    );
  }
}

class _MyPageView extends ConsumerWidget {
  const _MyPageView({required this.isLoggingOut, required this.onLogout});

  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        _SurfacePanel(
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '펫누림 회원',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 4),
                    Text('소셜 계정으로 로그인됨'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionTitle(title: '계정'),
        const SizedBox(height: 10),
        const _ListItem(
          icon: Icons.account_circle_outlined,
          title: '내 정보',
          subtitle: '프로필과 연락처',
        ),
        const SizedBox(height: 10),
        const _ListItem(
          icon: Icons.pets_outlined,
          title: '반려동물 관리',
          subtitle: '등록된 반려동물',
        ),
        const SizedBox(height: 10),
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

class _ListPage extends StatelessWidget {
  const _ListPage({
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<_ListItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(description),
        const SizedBox(height: 18),
        for (final item in items) ...[item, const SizedBox(height: 10)],
      ],
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
