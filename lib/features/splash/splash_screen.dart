import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_bootstrap.dart';
import '../../app/widgets/route_step_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appBootstrapStateProvider, (previous, next) {
      next.whenData((state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(state.nextRoute);
          }
        });
      });
    });

    final bootstrapState = ref.watch(appBootstrapStateProvider);

    return bootstrapState.when(
      loading: () => const RouteStepScreen(
        title: '펫누림',
        eyebrow: '앱 시작점',
        description: '저장된 토큰과 온보딩 상태를 확인하고 있습니다.',
        details: [
          'access token은 보안 저장소에서 읽습니다.',
          '온보딩 완료 여부는 로컬 설정 저장소에서 읽습니다.',
        ],
      ),
      error: (error, stackTrace) => RouteStepScreen(
        title: '시작 상태 확인 실패',
        eyebrow: '앱 시작점',
        description: '앱 시작 상태를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요.',
        details: [error.toString()],
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => ref.invalidate(appBootstrapStateProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ),
        ],
      ),
      data: (state) => RouteStepScreen(
        title: '펫누림',
        eyebrow: '앱 시작점',
        description: '시작 상태 확인을 마쳤습니다. 다음 화면으로 이동합니다.',
        details: [
          '다음 경로: ${state.nextRoute}',
          '온보딩 완료: ${state.onboardingSeen ? '예' : '아니오'}',
          '로그인 토큰: ${state.isAuthenticated ? '있음' : '없음'}',
        ],
      ),
    );
  }
}
