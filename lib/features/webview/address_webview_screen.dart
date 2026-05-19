import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_routes.dart';
import '../../app/widgets/route_step_screen.dart';

class AddressWebViewScreen extends StatelessWidget {
  const AddressWebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RouteStepScreen(
      title: '주소검색 WebView',
      eyebrow: '부분 WebView 후보',
      description: 'Daum/Kakao 주소검색처럼 웹 서비스가 강제되는 흐름만 별도 WebView 화면으로 분리합니다.',
      details: const [
        '전체 앱을 WebView로 감싸지 않고 필요한 기능만 좁게 분리합니다.',
        '선택된 주소는 회원정보 입력 상태로 되돌려 전달할 예정입니다.',
      ],
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.go(AppRoutes.signupProfile),
            icon: const Icon(Icons.check),
            label: const Text('주소 선택 후 돌아가기'),
          ),
        ),
      ],
    );
  }
}
