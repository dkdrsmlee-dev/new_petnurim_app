import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/widgets/route_step_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteStepScreen(
      title: '회원정보 입력',
      eyebrow: '회원가입 3단계',
      description: '주소, 상세 주소, 생년월일처럼 회원가입에 필요한 추가 정보를 입력합니다.',
      details: const [
        '이름, 휴대폰번호, 연결 계정은 본인인증과 소셜 로그인 결과로 채웁니다.',
        '주소검색은 웹 서비스 의존성이 높아 별도 WebView 화면 후보로 분리했습니다.',
      ],
      actions: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.addressWebView),
            icon: const Icon(Icons.map_outlined),
            label: const Text('주소검색 WebView 확인'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.signupComplete),
            icon: const Icon(Icons.save_outlined),
            label: const Text('회원정보 저장'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => context.go(AppRoutes.signupVerify),
            icon: const Icon(Icons.arrow_back),
            label: const Text('본인인증으로'),
          ),
        ),
      ],
    );
  }
}
