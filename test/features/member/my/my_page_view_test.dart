import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/features/member/data/member_repository.dart';
import 'package:new_petnurim_app/features/member/domain/member_info.dart';
import 'package:new_petnurim_app/features/member/domain/member_my_page.dart';
import 'package:new_petnurim_app/features/member/domain/member_withdrawal.dart';
import 'package:new_petnurim_app/features/member/my/my_page_view.dart';
import 'package:new_petnurim_app/core/widgets/section_title.dart';
import 'package:new_petnurim_app/core/widgets/pet_card.dart';
import 'package:new_petnurim_app/core/widgets/membership_card.dart';
import 'package:new_petnurim_app/core/widgets/list_button.dart';

class _FakeMemberRepository implements MemberRepository {
  @override
  Future<MemberMyPage> getMyPage() async {
    return const MemberMyPage(
      userId: 'test_user',
      name: '홍길동',
      email: 'test@example.com',
      joinDt: '2026-05-26T00:00:00.000Z',
    );
  }

  @override
  Future<MemberInfo> getMemberInfo() async {
    return const MemberInfo(
      name: '홍길동',
      email: 'test@example.com',
      phoneNumber: '010-1234-5678',
      address: '서울시 강남구',
      birthDate: '20000101',
    );
  }

  @override
  Future<MemberWithdrawResult> withdraw({
    required String reasonCode,
    String? reasonText,
  }) async {
    return const MemberWithdrawResult(
      withdrawalStatus: 'COMPLETED',
      effectiveDt: '2026-05-26 12:00:00',
    );
  }

  @override
  Future<void> updateMemberInfo({
    required String name,
    required String email,
    required String address,
  }) async {}

  @override
  Future<void> updateMemberAddress({
    required String zipCode,
    required String address1,
    required String address2,
  }) async {}
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  testWidgets('MyPageView UI Layout Test - Membership removed, My Pet header and card exists', (WidgetTester tester) async {
    // Set a portrait layout constraints for mobile testing
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Render the MyPageView with overridden MemberRepository
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            overrides: [
              memberRepositoryProvider.overrideWithValue(_FakeMemberRepository()),
            ],
            child: MyPageView(
              isLoggingOut: false,
              onLogout: () {},
            ),
          ),
        ),
      ),
    );

    // Wait for the FutureProvider to load the data
    await tester.pumpAndSettle();

    // 2. Verify that the membership card is NOT present in the page
    expect(find.byType(NurimMembershipCard), findsNothing);

    // 3. Verify that the profile name is correctly rendered
    expect(find.text('홍길동님 반가워요 :)'), findsOneWidget);

    // 4. Verify that the first separator (grey divider bar) is present
    // It is a Container with height 8 and color 0xFFF4F6F8
    final dividerFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.constraints?.maxHeight == 8 &&
          widget.color == const Color(0xFFF4F6F8),
    );
    expect(dividerFinder, findsAtLeast(1)); 

    // 5. Verify that '마이 펫' section title and '전체보기' action label is present
    expect(find.byType(NurimSectionTitle), findsOneWidget);
    expect(find.text('마이 펫'), findsOneWidget);
    expect(find.text('전체보기'), findsOneWidget);

    // 6. Verify that NurimMyPetSection widget is present
    expect(find.byType(NurimMyPetSection), findsOneWidget);
    
    // 7. Verify that pet names (콩두리, 초코) are rendered inside the pet card section
    expect(find.text('콩두리'), findsOneWidget);
    expect(find.text('초코'), findsOneWidget);

    // 8. Scroll down to show list buttons at the bottom
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('설정'), 100.0, scrollable: scrollable);
    await tester.pumpAndSettle();

    // 9. Verify the list buttons: 고객센터, 서비스 약관, 설정 are present after scrolling
    expect(find.byType(NurimListButton), findsNWidgets(3));
    expect(find.text('고객센터'), findsOneWidget);
    expect(find.text('서비스 약관'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);

    // 10. Verify that old menus "리워드 관리" and "결제수단 관리" are NOT present
    expect(find.text('리워드 관리'), findsNothing);
    expect(find.text('결제수단 관리'), findsNothing);
  });
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
