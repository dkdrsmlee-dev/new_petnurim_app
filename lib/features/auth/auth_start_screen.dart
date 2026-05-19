import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/widgets/route_step_screen.dart';

class AuthStartScreen extends StatelessWidget {
  const AuthStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteStepScreen(
      title: '서비스 시작하기',
      eyebrow: '인증 진입',
      description: '서버에서 사용 가능한 로그인 수단을 확인하고 Kakao/Naver 로그인을 시작할 화면입니다.',
      details: const [
        '4단계에서 Kakao SDK와 Naver 네이티브 채널을 연결합니다.',
        '신규 회원은 약관 동의로, 기존 회원은 홈으로 이동합니다.',
      ],
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.signupTerms),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('회원가입 흐름 확인'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('기존 회원 홈 확인'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => context.go(AppRoutes.splash),
            icon: const Icon(Icons.arrow_back),
            label: const Text('처음으로'),
          ),
        ),
      ],
    );
  }
}
