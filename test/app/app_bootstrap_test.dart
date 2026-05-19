import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/app/app_bootstrap.dart';
import 'package:new_petnurim_app/app/app_routes.dart';
import 'package:new_petnurim_app/core/storage/onboarding_storage.dart';
import 'package:new_petnurim_app/core/storage/token_storage.dart';

void main() {
  test('토큰이 없고 온보딩을 보지 않았다면 온보딩으로 이동한다', () async {
    final service = AppBootstrapService(
      tokenStorage: InMemoryTokenStorage(),
      onboardingStorage: InMemoryOnboardingStorage(),
    );

    final state = await service.load();

    expect(state.destination, AppBootstrapDestination.onboarding);
    expect(state.nextRoute, AppRoutes.onboarding);
  });

  test('토큰이 없고 온보딩을 봤다면 로그인 시작으로 이동한다', () async {
    final service = AppBootstrapService(
      tokenStorage: InMemoryTokenStorage(),
      onboardingStorage: InMemoryOnboardingStorage(initialSeen: true),
    );

    final state = await service.load();

    expect(state.destination, AppBootstrapDestination.authStart);
    expect(state.nextRoute, AppRoutes.authStart);
  });

  test('토큰이 있으면 온보딩 여부와 관계없이 홈으로 이동한다', () async {
    final service = AppBootstrapService(
      tokenStorage: InMemoryTokenStorage(initialAccessToken: ' access-token '),
      onboardingStorage: InMemoryOnboardingStorage(),
    );

    final state = await service.load();

    expect(state.destination, AppBootstrapDestination.home);
    expect(state.nextRoute, AppRoutes.home);
    expect(state.accessToken, 'access-token');
  });
}
