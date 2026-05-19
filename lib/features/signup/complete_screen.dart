import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/widgets/route_step_screen.dart';

class CompleteScreen extends StatelessWidget {
  const CompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteStepScreen(
      title: '가입 완료',
      eyebrow: '회원가입 완료',
      description: '회원가입 완료 API에서 access token을 받은 뒤 토큰을 저장하고 홈으로 이동합니다.',
      details: const [
        '3단계에서 토큰 저장소를 실제 secure storage 구현으로 교체합니다.',
        '완료 후에는 회원가입 임시 토큰과 진행 상태를 정리합니다.',
      ],
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.home_outlined),
            label: const Text('홈으로 이동'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => context.go(AppRoutes.signupProfile),
            icon: const Icon(Icons.arrow_back),
            label: const Text('회원정보 입력으로'),
          ),
        ),
      ],
    );
  }
}
