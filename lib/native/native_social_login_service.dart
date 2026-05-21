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
    final OAuthToken oauthToken;
    final User user;
    try {
      oauthToken = await _requestKakaoToken();
      user = await UserApi.instance.me();
    } on PlatformException catch (error) {
      throw _platformExceptionToAuthException(error);
    } on KakaoClientException catch (error) {
      throw _kakaoExceptionToAuthException(error);
    } on KakaoAuthException catch (error) {
      throw _kakaoExceptionToAuthException(error);
    } on KakaoApiException catch (error) {
      throw _kakaoExceptionToAuthException(error);
    } on KakaoException catch (error) {
      throw _kakaoExceptionToAuthException(error);
    }

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

  Future<OAuthToken> _requestKakaoToken() async {
    if (!await isKakaoTalkInstalled()) {
      return UserApi.instance.loginWithKakaoAccount();
    }

    try {
      return await UserApi.instance.loginWithKakaoTalk();
    } on PlatformException catch (error) {
      if (_isPlatformCancelled(error)) {
        throw const SocialLoginCancelledException('카카오 로그인이 취소되었습니다.');
      }

      return UserApi.instance.loginWithKakaoAccount();
    } on KakaoClientException catch (error) {
      if (_isKakaoCancelled(error)) {
        throw const SocialLoginCancelledException('카카오 로그인이 취소되었습니다.');
      }

      return UserApi.instance.loginWithKakaoAccount();
    } on KakaoAuthException catch (error) {
      if (_isKakaoCancelled(error)) {
        throw const SocialLoginCancelledException('카카오 로그인이 취소되었습니다.');
      }

      return UserApi.instance.loginWithKakaoAccount();
    } on KakaoException {
      return UserApi.instance.loginWithKakaoAccount();
    }
  }

  bool _isPlatformCancelled(PlatformException error) {
    final code = error.code.toLowerCase();
    return code == 'canceled' || code == 'cancelled' || code == 'access_denied';
  }

  AuthException _platformExceptionToAuthException(PlatformException error) {
    if (_isPlatformCancelled(error)) {
      return const SocialLoginCancelledException('카카오 로그인이 취소되었습니다.');
    }

    final message = error.message?.trim();
    if (message == null || message.isEmpty) {
      return AuthException('카카오 네이티브 호출 오류가 발생했습니다. (${error.code})');
    }

    return AuthException('카카오 네이티브 호출 오류: $message (${error.code})');
  }

  bool _isKakaoCancelled(KakaoException error) {
    if (error is KakaoClientException) {
      return error.reason == ClientErrorCause.cancelled;
    }

    if (error is KakaoAuthException) {
      return error.error == AuthErrorCause.accessDenied;
    }

    if (error is KakaoApiException) {
      return error.code == ApiErrorCause.accessDenied;
    }

    return false;
  }

  AuthException _kakaoExceptionToAuthException(KakaoException error) {
    if (_isKakaoCancelled(error)) {
      return const SocialLoginCancelledException('카카오 로그인이 취소되었습니다.');
    }

    if (error is KakaoAuthException) {
      return AuthException(_kakaoAuthMessage(error));
    }

    if (error is KakaoApiException) {
      return AuthException('카카오 API 오류: ${error.msg} (${error.code.name})');
    }

    if (error is KakaoClientException) {
      return AuthException('카카오 SDK 오류: ${error.msg} (${error.reason.name})');
    }

    final message = error.message?.trim();
    if (message == null || message.isEmpty) {
      return const AuthException('카카오 SDK 오류가 발생했습니다.');
    }

    return AuthException('카카오 SDK 오류: $message');
  }

  String _kakaoAuthMessage(KakaoAuthException error) {
    final detail = error.errorDescription?.trim();
    final suffix = '(${error.error.name})';

    switch (error.error) {
      case AuthErrorCause.invalidClient:
        return '카카오 앱 키가 올바르지 않습니다. 카카오 개발자 콘솔의 앱 키 설정을 확인해 주세요. $suffix';
      case AuthErrorCause.misconfigured:
        return '카카오 앱 플랫폼 설정이 올바르지 않습니다. Android 패키지명, 키 해시, Redirect URI를 확인해 주세요. $suffix';
      case AuthErrorCause.invalidScope:
        return '카카오 동의항목 설정이 올바르지 않습니다. 카카오 개발자 콘솔의 동의항목을 확인해 주세요. $suffix';
      case AuthErrorCause.unauthorized:
        return '카카오 앱에 로그인 권한이 없습니다. 카카오 개발자 콘솔의 권한 설정을 확인해 주세요. $suffix';
      case AuthErrorCause.serverError:
        return '카카오 서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요. $suffix';
      case AuthErrorCause.invalidRequest:
      case AuthErrorCause.invalidGrant:
      case AuthErrorCause.accessDenied:
      case AuthErrorCause.unknown:
        if (detail == null || detail.isEmpty) {
          return '카카오 인증 오류가 발생했습니다. $suffix';
        }

        return '카카오 인증 오류: $detail $suffix';
    }
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
