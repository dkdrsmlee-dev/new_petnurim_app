import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/widgets/route_step_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteStepScreen(
      title: '온보딩',
      eyebrow: '처음 실행 흐름',
      description: '펫누림의 핵심 가치와 주요 기능을 소개한 뒤 로그인 시작 화면으로 보냅니다.',
      details: const [
        '온보딩 완료 여부는 이후 로컬 저장소에 보관합니다.',
        '실제 UI 단계에서 슬라이드와 진행 점을 구성합니다.',
      ],
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.authStart),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('서비스 시작하기'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => context.go(AppRoutes.splash),
            icon: const Icon(Icons.refresh),
            label: const Text('처음으로'),
          ),
        ),
      ],
    );
  }
}
