// 기본 Flutter 위젯 테스트입니다.
// WidgetTester로 탭 같은 사용자 동작을 실행하고 화면 상태를 검증합니다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_petnurim_app/app/petnurim_app.dart';

void main() {
  testWidgets('초기 라우팅과 온보딩 이동 스모크 테스트', (WidgetTester tester) async {
    // 앱을 렌더링합니다.
    await tester.pumpWidget(const ProviderScope(child: PetnurimApp()));
    await tester.pumpAndSettle();

    // 루트 경로에서 스플래시 역할의 시작 화면을 보여줍니다.
    expect(find.text('펫누림'), findsWidgets);
    expect(find.text('온보딩 보기'), findsOneWidget);

    // 라우터를 통해 온보딩 화면으로 이동합니다.
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    expect(find.text('온보딩'), findsWidgets);
    expect(find.text('서비스 시작하기'), findsOneWidget);
  });
}
