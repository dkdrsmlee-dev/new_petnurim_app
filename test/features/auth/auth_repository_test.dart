import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:new_petnurim_app/core/api/api_client.dart';
import 'package:new_petnurim_app/core/config/app_config.dart';
import 'package:new_petnurim_app/core/storage/token_storage.dart';
import 'package:new_petnurim_app/features/auth/data/auth_repository.dart';
import 'package:new_petnurim_app/features/auth/domain/social_login_result.dart';
import 'package:new_petnurim_app/features/auth/domain/social_provider.dart';
import 'package:new_petnurim_app/native/native_social_login_service.dart';

void main() {
  test('기존 회원 소셜 로그인은 서버 access token을 저장한다', () async {
    final tokenStorage = InMemoryTokenStorage();
    final repository = BackendAuthRepository(
      apiClient: ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'https://api.petnurim.test/api/v1/auth/social/kakao',
          );
          expect(jsonDecode(request.body), {
            'provider': 'KAKAO',
            'providerAccessToken': 'provider-token',
          });

          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'code': 'COMMON.SUCCESS',
                'data': {
                  'nextStep': 'home',
                  'accessToken': 'server-access-token',
                  'profile': {'name': '누림'},
                },
              }),
            ),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
      tokenStorage: tokenStorage,
      nativeSocialLoginService: const _FakeNativeSocialLoginService(),
    );

    final result = await repository.loginWithProvider(SocialProvider.kakao);

    expect(result.nextStep, SocialLoginNextStep.home);
    expect(result.profile.name, '누림');
    expect(await tokenStorage.readAccessToken(), 'server-access-token');
  });

  test('신규 회원 소셜 로그인은 signup token을 다음 단계 자격으로 사용한다', () async {
    final tokenStorage = InMemoryTokenStorage();
    final repository = BackendAuthRepository(
      apiClient: ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://api.petnurim.test'),
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'COMMON.SUCCESS',
              'data': {
                'nextStep': 'signup',
                'signupToken': 'signup-token',
                'profile': {'phone': '010-0000-0000'},
              },
            }),
            200,
          );
        }),
      ),
      tokenStorage: tokenStorage,
      nativeSocialLoginService: const _FakeNativeSocialLoginService(),
    );

    final result = await repository.loginWithProvider(SocialProvider.kakao);

    expect(result.nextStep, SocialLoginNextStep.signup);
    expect(result.credentialForNextStep, 'signup-token');
    expect(result.profile.phone, '010-0000-0000');
    expect(await tokenStorage.readAccessToken(), isNull);
  });
}

class _FakeNativeSocialLoginService implements NativeSocialLoginService {
  const _FakeNativeSocialLoginService();

  @override
  Future<NativeSocialLoginResult> loginWithProvider(
    SocialProvider provider,
  ) async {
    return NativeSocialLoginResult(
      provider: provider,
      providerAccessToken: 'provider-token',
      providerRefreshToken: 'provider-refresh-token',
      providerUserId: 'provider-user-id',
      name: '${provider.label} 사용자',
      phone: '',
    );
  }
}
