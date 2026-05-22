import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/widgets/card_banner.dart';

void main() {
  testWidgets('NurimCardBanner renders correctly with default widgets', (
    WidgetTester tester,
  ) async {
    bool isTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NurimCardBanner(
            title: '출석 체크 리워드',
            subtitle: '매일 출석하고 포인트 받자!',
            pointText: '+100P',
            statusText: '연속 출석',
            dayText: '15일',
            onTap: () {
              isTapped = true;
            },
          ),
        ),
      ),
    );

    // Verify text elements are rendered
    expect(find.text('출석 체크 리워드'), findsOneWidget);
    expect(find.text('매일 출석하고 포인트 받자!'), findsOneWidget);
    expect(find.text('+100P'), findsOneWidget);
    expect(find.text('연속 출석'), findsOneWidget);
    expect(find.text('15일'), findsOneWidget);

    // Verify default giftbox icon (default bannerImg placeholder) is rendered
    expect(find.byIcon(Icons.card_giftcard), findsOneWidget);

    // Verify default fire icon (default bannerIcon placeholder) is rendered
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);

    // Verify tap callback triggers
    await tester.tap(find.byType(NurimCardBanner));
    await tester.pumpAndSettle();
    expect(isTapped, isTrue);
  });

  testWidgets('NurimCardBanner renders custom bannerImg and bannerIcon', (
    WidgetTester tester,
  ) async {
    const customImgKey = Key('custom_image');
    const customIconKey = Key('custom_icon');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NurimCardBanner(
            title: '출석 체크 리워드',
            subtitle: '매일 출석하고 포인트 받자!',
            pointText: '+100P',
            statusText: '연속 출석',
            dayText: '15일',
            bannerImg: SizedBox(
              key: customImgKey,
              width: 78,
              height: 78,
            ),
            bannerIcon: Icon(
              Icons.star,
              key: customIconKey,
            ),
          ),
        ),
      ),
    );

    // Verify default placeholders are not rendered
    expect(find.byIcon(Icons.card_giftcard), findsNothing);
    expect(find.byIcon(Icons.local_fire_department), findsNothing);

    // Verify custom widgets are rendered
    expect(find.byKey(customImgKey), findsOneWidget);
    expect(find.byKey(customIconKey), findsOneWidget);
  });

  testWidgets('NurimCardBannerSmall renders correctly with default widgets', (
    WidgetTester tester,
  ) async {
    bool isTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NurimCardBannerSmall(
            titleLine1: '매일 출석하고',
            titleLine2: '포인트 받기',
            pointText: '+100P',
            statusText: '연속 출석',
            dayText: '15일',
            onTap: () {
              isTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('매일 출석하고'), findsOneWidget);
    expect(find.text('포인트 받기'), findsOneWidget);
    expect(find.text('+100P'), findsOneWidget);
    expect(find.text('연속 출석'), findsOneWidget);
    expect(find.text('15일'), findsOneWidget);

    // Default 이미지 아이콘 렌더링 확인
    expect(find.byIcon(Icons.pets), findsOneWidget);
    // 화살표 아이콘 렌더링 확인
    expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);

    await tester.tap(find.byType(NurimCardBannerSmall));
    await tester.pumpAndSettle();
    expect(isTapped, isTrue);
  });

  testWidgets('NurimCardBannerSmall renders custom bannerImg', (
    WidgetTester tester,
  ) async {
    const customImgKey = Key('small_custom_image');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NurimCardBannerSmall(
            titleLine1: '매일 출석하고',
            titleLine2: '포인트 받기',
            pointText: '+100P',
            statusText: '연속 출석',
            dayText: '15일',
            bannerImg: SizedBox(
              key: customImgKey,
              width: 50,
              height: 50,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.pets), findsNothing);
    expect(find.byKey(customImgKey), findsOneWidget);
  });
}
