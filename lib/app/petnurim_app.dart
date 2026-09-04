import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import 'app_router.dart';
import 'app_theme.dart';

class PetnurimApp extends ConsumerWidget {
  const PetnurimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: '펫누림',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      // 시스템 글자 크기를 그대로 반영하면 고정 높이 박스(배지·칩 등)에서 글자가
      // 잘린다. 실단말 확인: 배율 1.3 에서 '도로명' 배지가 잘림.
      // 디자인 비율을 유지하는 선에서 상한을 둔다. 고정 높이를 최소 높이로
      // 바꾸는 작업이 끝나면 상한을 더 올릴 수 있다.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
    );
  }
}
