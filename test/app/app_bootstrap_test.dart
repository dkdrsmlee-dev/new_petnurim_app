import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/app/app_bootstrap.dart';
import 'package:new_petnurim_app/app/app_routes.dart';
import 'package:new_petnurim_app/core/storage/token_storage.dart';

void main() {
  test('토큰이 없으면 로그인 시작으로 이동한다', () async {
    final service = AppBootstrapService(
      tokenStorage: InMemoryTokenStorage(),
    );

    final state = await service.load();

    expect(state.destination, AppBootstrapDestination.authStart);
    expect(state.nextRoute, AppRoutes.authStart);
  });

  test('토큰이 있으면 홈으로 이동한다', () async {
    final service = AppBootstrapService(
      tokenStorage: InMemoryTokenStorage(initialAccessToken: ' access-token '),
    );

    final state = await service.load();

    expect(state.destination, AppBootstrapDestination.home);
    expect(state.nextRoute, AppRoutes.home);
    expect(state.accessToken, 'access-token');
  });
}
