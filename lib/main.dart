import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'app/app_bootstrap.dart';
import 'app/app_router.dart';
import 'app/app_routes.dart';
import 'app/petnurim_app.dart';
import 'core/api/api_client.dart';
import 'core/config/social_auth_config.dart';
import 'core/storage/token_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const socialAuthConfig = SocialAuthConfig();
  KakaoSdk.init(nativeAppKey: socialAuthConfig.kakaoNativeAppKey);

  runApp(
    ProviderScope(
      overrides: [
        socialAuthConfigProvider.overrideWithValue(socialAuthConfig),
        unauthorizedHandlerProvider.overrideWith((ref) {
          bool isRedirecting = false;
          return () async {
            if (isRedirecting) return;
            isRedirecting = true;
            try {
              await ref.read(tokenStorageProvider).clearTokens();
              ref.invalidate(appBootstrapStateProvider);
              ref.read(appRouterProvider).go(AppRoutes.authStart);
              scaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text('로그인 세션이 만료되었습니다. 다시 로그인해 주세요.'),
                ),
              );
            } finally {
              await Future.delayed(const Duration(seconds: 2));
              isRedirecting = false;
            }
          };
        }),
      ],
      child: const PetnurimApp(),
    ),
  );
}
