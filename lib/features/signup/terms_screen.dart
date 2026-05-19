import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/widgets/route_step_screen.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteStepScreen(
      title: '약관 동의',
      eyebrow: '회원가입 1단계',
      description: '활성화된 약관 목록을 불러오고 필수 약관 동의 여부를 저장합니다.',
      details: const [
        '약관 목록 API와 동의 저장 API는 3단계 이후 서비스로 옮깁니다.',
        '복잡한 HTML 본문이 내려오면 WebView 또는 HTML 렌더러 사용 여부를 판단합니다.',
      ],
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.signupVerify),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('본인인증 진행하기'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => context.go(AppRoutes.authStart),
            icon: const Icon(Icons.arrow_back),
            label: const Text('로그인 시작으로'),
          ),
        ),
      ],
    );
  }
}
