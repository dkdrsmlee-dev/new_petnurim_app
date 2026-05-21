// 기본 Flutter 위젯 테스트입니다.
// WidgetTester로 탭 같은 사용자 동작을 실행하고 화면 상태를 검증합니다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_petnurim_app/app/petnurim_app.dart';
import 'package:new_petnurim_app/core/storage/onboarding_storage.dart';
import 'package:new_petnurim_app/core/storage/token_storage.dart';
import 'package:new_petnurim_app/features/auth/application/auth_providers.dart';
import 'package:new_petnurim_app/features/auth/data/auth_repository.dart';
import 'package:new_petnurim_app/features/auth/domain/login_config.dart';
import 'package:new_petnurim_app/features/auth/domain/social_login_result.dart';
import 'package:new_petnurim_app/features/auth/domain/social_provider.dart';

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
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
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
    expect(find.text('계정으로 바로 시작하세요'), findsOneWidget);
    expect(find.text('카카오로 계속하기'), findsOneWidget);
    expect(find.text('네이버로 계속하기'), findsOneWidget);
  });

  testWidgets('토큰이 있으면 홈으로 이동한다', (WidgetTester tester) async {
    final tokenStorage = InMemoryTokenStorage(
      initialAccessToken: 'access-token',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          onboardingStorageProvider.overrideWithValue(
            InMemoryOnboardingStorage(),
          ),
        ],
        child: const PetnurimApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('펫누림 홈'), findsOneWidget);
    expect(find.text('오늘의 펫누림'), findsOneWidget);
    expect(find.text('진료 준비하기'), findsOneWidget);
    expect(await tokenStorage.readAccessToken(), 'access-token');
  });

  testWidgets('홈 마이페이지에서 로그아웃하면 토큰을 지우고 로그인 화면으로 이동한다', (
    WidgetTester tester,
  ) async {
    final tokenStorage = InMemoryTokenStorage(
      initialAccessToken: 'access-token',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          onboardingStorageProvider.overrideWithValue(
            InMemoryOnboardingStorage(initialSeen: true),
          ),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const PetnurimApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.text('소셜 계정으로 로그인됨'), findsOneWidget);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(await tokenStorage.readAccessToken(), isNull);
    expect(find.text('계정으로 바로 시작하세요'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<LoginConfig> fetchLoginConfig() async {
    return const LoginConfig.allEnabled();
  }

  @override
  Future<SocialLoginResult> loginWithProvider(SocialProvider provider) async {
    return SocialLoginResult(
      provider: provider,
      nextStep: SocialLoginNextStep.signup,
      signupToken: 'signup-token',
      profile: SocialLoginProfile(
        provider: provider,
        providerLabel: provider.label,
        name: '${provider.label} 사용자',
        phone: '',
      ),
    );
  }
}
