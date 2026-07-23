// 기본 Flutter 위젯 테스트입니다.
// WidgetTester로 탭 같은 사용자 동작을 실행하고 화면 상태를 검증합니다.

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_petnurim_app/app/petnurim_app.dart';
import 'package:new_petnurim_app/core/storage/token_storage.dart';
import 'package:new_petnurim_app/features/auth/application/auth_providers.dart';
import 'package:new_petnurim_app/features/auth/data/auth_repository.dart';
import 'package:new_petnurim_app/features/auth/domain/login_config.dart';
import 'package:new_petnurim_app/features/auth/domain/social_login_result.dart';
import 'package:new_petnurim_app/features/auth/domain/social_provider.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  testWidgets('토큰이 없으면 로그인 시작 화면으로 이동한다', (WidgetTester tester) async {
    // 앱을 렌더링합니다.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const PetnurimApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 온보딩 없이 곧바로 로그인 시작 화면이 노출됩니다.
    expect(find.text('안녕하세요 :)\n회원가입 후 이용해 주세요.'), findsOneWidget);
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('네이버로 시작하기'), findsOneWidget);
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

  @override
  Future<void> logout() async {}
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
