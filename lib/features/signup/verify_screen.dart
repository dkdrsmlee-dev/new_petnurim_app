import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/widgets/route_step_screen.dart';

class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteStepScreen(
      title: '본인인증',
      eyebrow: '회원가입 2단계',
      description: 'PASS 또는 인증 제공사 흐름을 통해 회원의 이름과 휴대폰 정보를 확정합니다.',
      details: const [
        '제공사가 웹 흐름을 요구하면 이 단계에서 제한적 WebView를 사용합니다.',
        '인증 완료 후 회원 초기 정보 API를 호출해 프로필 입력 화면으로 넘깁니다.',
      ],
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.signupProfile),
            icon: const Icon(Icons.badge_outlined),
            label: const Text('회원정보 입력하기'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => context.go(AppRoutes.signupTerms),
            icon: const Icon(Icons.arrow_back),
            label: const Text('약관 동의로'),
          ),
        ),
      ],
    );
  }
}
