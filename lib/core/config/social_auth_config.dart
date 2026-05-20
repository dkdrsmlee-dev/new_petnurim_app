import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialAuthConfig {
  const SocialAuthConfig({
    this.kakaoNativeAppKey = const String.fromEnvironment(
      'KAKAO_NATIVE_APP_KEY',
      defaultValue: defaultKakaoNativeAppKey,
    ),
    this.naverClientId = const String.fromEnvironment(
      'NAVER_CLIENT_ID',
      defaultValue: defaultNaverClientId,
    ),
    this.naverClientSecret = const String.fromEnvironment(
      'NAVER_CLIENT_SECRET',
      defaultValue: '',
    ),
    this.naverClientName = const String.fromEnvironment(
      'NAVER_CLIENT_NAME',
      defaultValue: defaultNaverClientName,
    ),
    this.naverIosUrlScheme = const String.fromEnvironment(
      'NAVER_IOS_URL_SCHEME',
      defaultValue: defaultNaverIosUrlScheme,
    ),
    this.naverAuthChannelName = 'petnurim/naver_auth',
  });

  static const defaultKakaoNativeAppKey = '930bf238e56cb22cf6484fa8af790a5a';
  static const defaultNaverClientId = 'rOPP7lBMsxvpvDDFcrwF';
  static const defaultNaverClientName = 'web3_네이버로그인';
  static const defaultNaverIosUrlScheme = 'com.dkdr.newPetnurimApp';

  final String kakaoNativeAppKey;
  final String naverClientId;
  final String naverClientSecret;
  final String naverClientName;
  final String naverIosUrlScheme;
  final String naverAuthChannelName;
}

final socialAuthConfigProvider = Provider<SocialAuthConfig>((ref) {
  return const SocialAuthConfig();
});
