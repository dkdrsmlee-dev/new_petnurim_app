import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/widgets/my_info_row.dart';

void main() {
  testWidgets('NurimMyInfoRow renders texts and button correctly', (
    WidgetTester tester,
  ) async {
    bool actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NurimMyInfoRow(
            labelText: '테스트 라벨',
            primaryValue: 'test@example.com',
            secondaryValue: '(테스트)',
            actionLabel: '액션',
            onActionPressed: () => actionTapped = true,
          ),
        ),
      ),
    );

    // 라벨 및 값들 렌더링 확인
    expect(find.text('테스트 라벨'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('(테스트)'), findsOneWidget);
    expect(find.text('액션'), findsOneWidget);

    // 버튼 클릭 동작 확인
    await tester.tap(find.text('액션'));
    await tester.pumpAndSettle();
    expect(actionTapped, isTrue);
  });

  testWidgets('NurimMyInfoRow does not render action button when showActionButton is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NurimMyInfoRow(
            labelText: '테스트 라벨',
            primaryValue: 'test@example.com',
            showActionButton: false,
          ),
        ),
      ),
    );

    expect(find.text('관리'), findsNothing);
  });
}
