import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/widgets/membership_card.dart';

void main() {
  testWidgets('NurimMembershipCard renders all elements correctly', (
    WidgetTester tester,
  ) async {
    bool benefitTapped = false;
    bool paymentTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NurimMembershipCard(
            tierName: '브론즈',
            nextBillingDate: '2026.05.12',
            monthlyFee: '10,000원',
            onBenefitTapped: () => benefitTapped = true,
            onPaymentHistoryTapped: () => paymentTapped = true,
          ),
        ),
      ),
    );

    // 등급명 확인
    expect(find.text('브론즈'), findsOneWidget);
    // 배지 확인
    expect(find.text('현재 이용 중'), findsOneWidget);
    // 결제 정보 확인
    expect(find.text('다음 결제일'), findsOneWidget);
    expect(find.text('2026.05.12'), findsOneWidget);
    expect(find.text('월 구독료'), findsOneWidget);
    expect(find.text('10,000원'), findsOneWidget);
    // 리스트 항목 확인
    expect(find.text('멤버십 혜택'), findsOneWidget);
    expect(find.text('결제 내역'), findsOneWidget);

    // "멤버십 혜택" 탭
    await tester.tap(find.text('멤버십 혜택'));
    await tester.pumpAndSettle();
    expect(benefitTapped, isTrue);

    // "결제 내역" 탭
    await tester.tap(find.text('결제 내역'));
    await tester.pumpAndSettle();
    expect(paymentTapped, isTrue);
  });

  testWidgets('NurimMembershipCard custom statusLabel renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NurimMembershipCard(
            tierName: '골드',
            nextBillingDate: '2026.06.01',
            monthlyFee: '20,000원',
            statusLabel: '구독 중',
          ),
        ),
      ),
    );

    expect(find.text('골드'), findsOneWidget);
    expect(find.text('구독 중'), findsOneWidget);
    expect(find.text('2026.06.01'), findsOneWidget);
    expect(find.text('20,000원'), findsOneWidget);
  });
}
