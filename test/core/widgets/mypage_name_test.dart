import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/widgets/mypage_name.dart';

void main() {
  testWidgets('NurimMypageName UI spec matching test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NurimMypageName(name: '홍길동'),
        ),
      ),
    );

    // 1. Verify avatar contains the first character '홍'
    expect(find.text('홍'), findsOneWidget);

    final avatarFinder = find.byType(CircleAvatar);
    expect(avatarFinder, findsOneWidget);
    final CircleAvatar avatar = tester.widget(avatarFinder);
    expect(avatar.radius, 18.0); // 36px diameter
    expect(avatar.backgroundColor, const Color(0xFF7F4FFF)); // Violet color

    // 2. Verify containing rich text message
    expect(find.textContaining('홍길동님 반가워요 :)'), findsOneWidget);
  });
}
