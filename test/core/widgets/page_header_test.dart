import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/widgets/page_header.dart';

void main() {
  testWidgets('NurimPageHeader renders title and back button correctly', (
    WidgetTester tester,
  ) async {
    bool backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: NurimPageHeader(
            title: '테스트 타이틀',
            onBackPressed: () => backPressed = true,
          ),
          body: const SizedBox(),
        ),
      ),
    );

    // 타이틀 텍스트가 정상 렌더링되는지 확인
    expect(find.text('테스트 타이틀'), findsOneWidget);

    // 뒤로가기 아이콘 버튼이 존재하는지 확인
    final backButtonFinder = find.byType(IconButton);
    expect(backButtonFinder, findsOneWidget);

    // 뒤로가기 버튼 누르면 콜백이 실행되는지 확인
    await tester.tap(backButtonFinder);
    await tester.pumpAndSettle();
    expect(backPressed, isTrue);
  });

  testWidgets('NurimPageHeader does not render back button when showBackButton is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: NurimPageHeader(
            title: '헤더 타이틀',
            showBackButton: false,
          ),
          body: const SizedBox(),
        ),
      ),
    );

    // 뒤로가기 버튼이 렌더링되지 않음을 확인
    expect(find.byType(IconButton), findsNothing);
  });
}
