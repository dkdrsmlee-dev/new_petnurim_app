import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import '../core/config/social_auth_config.dart';
import '../features/auth/domain/auth_exception.dart';
import '../features/auth/domain/social_provider.dart';

abstract interface class NativeSocialLoginService {
  Future<NativeSocialLoginResult> loginWithProvider(SocialProvider provider);
}

class NativeSocialLoginResult {
  const NativeSocialLoginResult({
    required this.provider,
    required this.providerAccessToken,
    this.providerRefreshToken,
    this.providerUserId,
    this.name,
    this.phone,
  });

  final SocialProvider provider;
  final String providerAccessToken;
  final String? providerRefreshToken;
  final String? providerUserId;
  final String? name;
  final String? phone;
}

class KakaoNaverSocialLoginService implements NativeSocialLoginService {
  KakaoNaverSocialLoginService({required SocialAuthConfig config})
    : _config = config,
      _naverAuthChannel = MethodChannel(config.naverAuthChannelName);

  final SocialAuthConfig _config;
  final MethodChannel _naverAuthChannel;

  @override
  Future<NativeSocialLoginResult> loginWithProvider(SocialProvider provider) {
    switch (provider) {
      case SocialProvider.kakao:
        return _loginWithKakao();
      case SocialProvider.naver:
        return _loginWithNaver();
    }
  }

  Future<NativeSocialLoginResult> _loginWithKakao() async {
    late final OAuthToken oauthToken;

    if (await isKakaoTalkInstalled()) {
      try {
        oauthToken = await UserApi.instance.loginWithKakaoTalk();
      } on PlatformException catch (error) {
        if (error.code == 'CANCELED') {
          throw const SocialLoginCancelledException('카카오 로그인이 취소되었습니다.');
        }

        oauthToken = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      oauthToken = await UserApi.instance.loginWithKakaoAccount();
    }

    final user = await UserApi.instance.me();
    final accessToken = oauthToken.accessToken.trim();
    if (accessToken.isEmpty) {
      throw const AuthException('카카오 access token을 받지 못했습니다.');
    }

    return NativeSocialLoginResult(
      provider: SocialProvider.kakao,
      providerAccessToken: accessToken,
      providerRefreshToken: oauthToken.refreshToken,
      providerUserId: '${user.id}',
      name: user.kakaoAccount?.profile?.nickname?.trim(),
      phone: user.kakaoAccount?.phoneNumber?.trim(),
    );
  }

  Future<NativeSocialLoginResult> _loginWithNaver() async {
    final clientSecret = _config.naverClientSecret.trim();
    if (clientSecret.isEmpty) {
      throw const AuthException(
        '네이버 Client Secret이 설정되지 않았습니다. '
        '--dart-define=NAVER_CLIENT_SECRET=... 값을 넣어 실행해 주세요.',
      );
    }

    final result = await _naverAuthChannel
        .invokeMapMethod<String, dynamic>('login', {
          'clientId': _config.naverClientId,
          'clientSecret': clientSecret,
          'clientName': _config.naverClientName,
          'urlScheme': _config.naverIosUrlScheme,
        });

    if (result == null || result.isEmpty) {
      throw const AuthException('네이버 로그인 결과를 받지 못했습니다.');
    }

    final payload = result.map(
      (key, value) => MapEntry(key, value?.toString()),
    );
    final accessToken = payload['accessToken']?.trim() ?? '';
    if (accessToken.isEmpty) {
      throw const AuthException('네이버 access token을 받지 못했습니다.');
    }

    return NativeSocialLoginResult(
      provider: SocialProvider.naver,
      providerAccessToken: accessToken,
      providerRefreshToken: payload['refreshToken'],
      providerUserId: payload['userId'],
      name: payload['name'] ?? payload['nickname'],
      phone: payload['mobile'],
    );
  }
}
