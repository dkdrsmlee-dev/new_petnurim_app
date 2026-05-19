// 기본 Flutter 위젯 테스트입니다.
// WidgetTester로 탭 같은 사용자 동작을 실행하고 화면 상태를 검증합니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_petnurim_app/main.dart';

void main() {
  testWidgets('카운터 증가 스모크 테스트', (WidgetTester tester) async {
    // 앱을 렌더링합니다.
    await tester.pumpWidget(const MyApp());

    // 카운터가 0에서 시작하는지 확인합니다.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // 더하기 버튼을 누르고 화면을 갱신합니다.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // 카운터가 1로 증가했는지 확인합니다.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
