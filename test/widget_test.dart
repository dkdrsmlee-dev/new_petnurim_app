// 기본 Flutter 위젯 테스트입니다.
// WidgetTester로 탭 같은 사용자 동작을 실행하고 화면 상태를 검증합니다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_petnurim_app/app/petnurim_app.dart';
import 'package:new_petnurim_app/core/storage/onboarding_storage.dart';
import 'package:new_petnurim_app/core/storage/token_storage.dart';

void main() {
  testWidgets('토큰이 없고 온보딩 미완료이면 온보딩으로 이동한다', (WidgetTester tester) async {
    // 앱을 렌더링합니다.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          onboardingStorageProvider.overrideWithValue(
            InMemoryOnboardingStorage(),
          ),
        ],
        child: const PetnurimApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('온보딩'), findsWidgets);
    expect(find.text('서비스 시작하기'), findsOneWidget);

    // 온보딩 완료를 저장한 뒤 로그인 시작 화면으로 이동합니다.
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.text('서비스 시작하기'), findsWidgets);
    expect(find.text('회원가입 흐름 확인'), findsOneWidget);
  });

  testWidgets('토큰이 있으면 홈으로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(
            InMemoryTokenStorage(initialAccessToken: 'access-token'),
          ),
          onboardingStorageProvider.overrideWithValue(
            InMemoryOnboardingStorage(),
          ),
        ],
        child: const PetnurimApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('펫누림 홈'), findsOneWidget);
    expect(find.text('2단계 홈 골격'), findsOneWidget);
  });
}
