// 기본 Flutter 위젯 테스트입니다.
// WidgetTester로 탭 같은 사용자 동작을 실행하고 화면 상태를 검증합니다.

import 'dart:async';
import 'dart:io';

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
import 'package:new_petnurim_app/features/member/data/member_repository.dart';
import 'package:new_petnurim_app/features/member/domain/member_info.dart';
import 'package:new_petnurim_app/features/member/domain/member_my_page.dart';
import 'package:new_petnurim_app/features/member/domain/member_withdrawal.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

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

    expect(find.text('안녕하세요 :)\n회원가입 후 이용해 주세요.'), findsOneWidget);
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('네이버로 시작하기'), findsOneWidget);
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
          memberRepositoryProvider.overrideWithValue(_FakeMemberRepository()),
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
          memberRepositoryProvider.overrideWithValue(_FakeMemberRepository()),
        ],
        child: const PetnurimApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.text('홍길동님의 정보를 관리하실 수 있습니다.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('로그아웃'),
      220,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(await tokenStorage.readAccessToken(), isNull);
    expect(find.text('안녕하세요 :)\n회원가입 후 이용해 주세요.'), findsOneWidget);
  });

  testWidgets('나의 정보 화면에서 회원탈퇴하면 토큰을 지우고 로그인 화면으로 이동한다', (
    WidgetTester tester,
  ) async {
    final tokenStorage = InMemoryTokenStorage(
      initialAccessToken: 'access-token',
    );
    final memberRepository = _FakeMemberRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(tokenStorage),
          onboardingStorageProvider.overrideWithValue(
            InMemoryOnboardingStorage(initialSeen: true),
          ),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          memberRepositoryProvider.overrideWithValue(memberRepository),
        ],
        child: const PetnurimApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '정보 수정').first);
    await tester.pumpAndSettle();

    expect(find.text('나의 정보'), findsWidgets);
    expect(find.text('홍길동 님'), findsOneWidget);

    // 생년월일 변경 버튼 탭하여 바텀 시트가 잘 뜨는지 검증
    final birthDateRow = find.ancestor(
      of: find.text('생년월일'),
      matching: find.byType(Row),
    );
    final birthDateChangeButton = find.descendant(
      of: birthDateRow,
      matching: find.byType(OutlinedButton),
    );
    await tester.tap(birthDateChangeButton);
    await tester.pumpAndSettle();

    // 바텀 시트 안의 '완료' 버튼이 보이는지 확인 (바텀 시트가 정상적으로 열렸음을 의미)
    expect(find.text('완료'), findsOneWidget);
    await tester.tap(find.text('완료'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('회원탈퇴'),
      220,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('회원탈퇴'));
    await tester.pumpAndSettle();

    // 1. Check the consent box
    await tester.scrollUntilVisible(
      find.text('유의사항을 모두 확인하였으며, 회원 탈퇴에 동의 합니다.'),
      150,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('유의사항을 모두 확인하였으며, 회원 탈퇴에 동의 합니다.'));
    await tester.pumpAndSettle();

    // 2. Tap the '회원탈퇴' button
    await tester.tap(find.widgetWithText(ElevatedButton, '회원탈퇴'));
    await tester.pumpAndSettle();

    // 3. Confirm by tapping '탈퇴하기' in the dialog
    await tester.tap(find.text('탈퇴하기'));
    await tester.pumpAndSettle();

    expect(memberRepository.withdrawCalled, isTrue);
    expect(await tokenStorage.readAccessToken(), isNull);
    expect(find.text('안녕하세요 :)\n회원가입 후 이용해 주세요.'), findsOneWidget);
  });
}

Finder _verticalScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
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

class _FakeMemberRepository implements MemberRepository {
  bool withdrawCalled = false;

  @override
  Future<MemberMyPage> getMyPage() async {
    return const MemberMyPage(
      userId: 'hong01',
      name: '홍길동',
      email: 'email@email.co.kr',
      joinDt: '2026-02-27T00:00:00.000Z',
    );
  }

  @override
  Future<MemberInfo> getMemberInfo() async {
    return const MemberInfo(
      name: '홍길동',
      email: 'email@email.co.kr',
      phoneNumber: '010-1234-1234',
      address: '서울시 강남구 역삼동 123-45 12층 오크빌 1204호',
      birthDate: '20100307',
    );
  }

  @override
  Future<MemberWithdrawResult> withdraw({
    required String reasonCode,
    String? reasonText,
  }) async {
    withdrawCalled = true;
    return const MemberWithdrawResult(
      withdrawalStatus: 'COMPLETED',
      effectiveDt: '2026-05-21 10:00:00',
    );
  }
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  int get contentLength => _transparentImage.length;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final List<int> _transparentImage = [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
  0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x21, 0xf9, 0x04, 0x01, 0x00,
  0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
  0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3b
];
