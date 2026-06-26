import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'app/app_bootstrap.dart';
import 'app/app_router.dart';
import 'app/app_routes.dart';
import 'app/petnurim_app.dart';
import 'core/api/api_client.dart';
import 'core/config/social_auth_config.dart';
import 'core/storage/token_storage.dart';

/// 앱이 백그라운드 또는 종료 상태일 때 푸시 메시지를 수신하는 핸들러
/// (반드시 최상위 함수로 작성 및 @pragma 적용 필요)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("💤 [FCM 백그라운드 수신]: ${message.messageId}");
  // 여기서 알림 데이터를 파싱하거나 로컬 데이터 저장 등의 백그라운드 처리를 수행할 수 있습니다.
}

void main() async {
  // 플러터 프레임워크 바인딩 보장
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 파이어베이스 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. 백그라운드 푸시 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. iOS 포그라운드 알림 수신 시 배너/사운드 강제 노출 설정
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 4. 알림 권한 요청 (iOS 및 Android 13 이상)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('사용자 알림 동의 상태: ${settings.authorizationStatus}');

  // 5. 최초 FCM 토큰 발급 시도 (NestJS 백엔드 저장용)
  try {
    String? token = await messaging.getToken();
    print("🚨 [FCM 디바이스 토큰]: $token");
    // TODO: 로그인 상태인 경우, 즉시 이 토큰을 백엔드 서버에 전송해 두는 것이 안전합니다.
  } catch (e) {
    print("🚨 [FCM 디바이스 토큰 발급 실패]: $e");
  }

  // 6. 실시간 FCM 토큰 변경(갱신) 리스너 감지
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print("🔄 [FCM 토큰 갱신됨]: $newToken");
    // TODO: 로그인 상태인 경우, 즉시 백엔드 API로 새 토큰을 보내 회원 DB에 동기화해야 합니다.
  });

  // 카카오 SDK 및 소셜 로그인 설정 초기화
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
