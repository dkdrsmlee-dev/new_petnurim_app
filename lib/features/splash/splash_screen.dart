import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_bootstrap.dart';
import '../../app/widgets/route_step_screen.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 앱 초기화 상태(access token, onboarding 등) 확인 후 분기 처리
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

    return Scaffold(
      body: bootstrapState.when(
        loading: () => const _SplashBody(),
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
        // 로딩 완료 후 다음 화면으로 화면이 전환되는 찰나의 순간에도 스플래시 화면을 매끄럽게 유지해 줍니다.
        data: (state) => const _SplashBody(),
      ),
    );
  }
}

/// 피그마 시안 (node-id: 1160:36493) 규격에 맞춘 스플래시 UI 바디
class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      // 피그마 UI 배경색: var(--primary/default, #7f4fff)
      color: AppColors.primary,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: SvgPicture.asset(
          'assets/images/splash_logo_fill.svg',
          // 피그마 로고 원본 크기: w: 188px, h: 40px
          width: 188.0,
          height: 40.0,
          // SVG 내부 파싱 오류 방지를 위한 안전 틴트 필터
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
