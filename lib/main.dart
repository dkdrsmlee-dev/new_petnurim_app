import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'app/petnurim_app.dart';
import 'core/config/social_auth_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const socialAuthConfig = SocialAuthConfig();
  KakaoSdk.init(nativeAppKey: socialAuthConfig.kakaoNativeAppKey);

  runApp(
    ProviderScope(
      overrides: [socialAuthConfigProvider.overrideWithValue(socialAuthConfig)],
      child: const PetnurimApp(),
    ),
  );
}
