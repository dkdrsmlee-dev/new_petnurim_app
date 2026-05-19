import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/widgets/route_step_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteStepScreen(
      title: '펫누림',
      eyebrow: '앱 시작점',
      description: '저장된 토큰과 온보딩 상태를 확인한 뒤 다음 화면으로 이동할 진입 화면입니다.',
      details: const [
        '2단계에서는 라우팅 구조 확인을 위해 수동 이동 버튼을 제공합니다.',
        '3단계에서 토큰 저장소와 부트스트랩 로직을 연결합니다.',
      ],
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.onboarding),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('온보딩 보기'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.authStart),
            icon: const Icon(Icons.login),
            label: const Text('로그인 시작 화면'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.home_outlined),
            label: const Text('홈 화면 확인'),
          ),
        ),
      ],
    );
  }
}
