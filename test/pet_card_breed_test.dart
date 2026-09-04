import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/widgets/pet_card.dart';
import 'package:new_petnurim_app/core/widgets/pet_select_card.dart';

/// 품종 텍스트가 받는 폭을 잰다. 피그마는 품종만 폭을 양보하고(말줄임)
/// 나이·성별은 줄어들지 않는다 — Pet card 140, Pet select card 150.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
    await loader.load();
  });

  const longBreed = '브리티시 숏헤어 브리티시 숏헤어';

  Future<void> measure(
    WidgetTester tester,
    String label,
    Widget child,
    String breedText,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 900));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, fontFamily: 'Pretendard'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ),
      ),
    ));
    await tester.pump();
    final f = find.text(breedText);
    final w = tester.getSize(f).width;
    final age = tester.getSize(find.text('2살')).width;
    final gender = tester.getSize(find.text('남아')).width;
    // ignore: avoid_print
    print('$label  품종 ${w.toStringAsFixed(1)}dp  '
        '나이 ${age.toStringAsFixed(1)}  성별 ${gender.toStringAsFixed(1)}');
    // 나이·성별은 줄어들지 않고 품종만 남은 폭을 받아야 한다.
    expect(w, greaterThan(130),
        reason: '$label: 품종이 너무 좁다. 나이·성별까지 Flexible 이면 다시 잘린다.');
    expect(tester.takeException(), isNull, reason: '$label: 레이아웃 예외');
    await tester.binding.setSurfaceSize(null);
  }

  testWidgets('품종 폭 측정', (tester) async {
    await measure(
      tester,
      'NurimPetCard      (피그마 140)',
      const NurimPetCard(
        pet: NurimPetCardData(
          name: '콩두리',
          breed: longBreed,
          ageText: '2살',
          genderText: '남아',
          membershipTier: '브론즈',
          rewardText: '28,000P',
        ),
      ),
      longBreed,
    );
    await measure(
      tester,
      'PetSelectCard     (피그마 150)',
      const PetSelectCard(
        data: PetSelectCardData(
          name: '콩두리',
          breed: longBreed,
          ageText: '2살',
          genderText: '남아',
        ),
      ),
      longBreed,
    );
  }, timeout: const Timeout(Duration(seconds: 120)));
}
