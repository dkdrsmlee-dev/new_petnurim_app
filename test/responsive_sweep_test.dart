import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_petnurim_app/core/widgets/address_card.dart';
import 'package:new_petnurim_app/core/widgets/bottom_action_bar.dart';
import 'package:new_petnurim_app/core/widgets/bullit_text.dart';
import 'package:new_petnurim_app/core/widgets/calendar_stamp.dart';
import 'package:new_petnurim_app/core/widgets/card_banner.dart';
import 'package:new_petnurim_app/core/widgets/common_dialog.dart';
import 'package:new_petnurim_app/core/widgets/edge_button_dialog.dart';
import 'package:new_petnurim_app/core/widgets/form_fields.dart';
import 'package:new_petnurim_app/core/widgets/info_row.dart';
import 'package:new_petnurim_app/core/widgets/last_login_badge.dart';
import 'package:new_petnurim_app/core/widgets/list_button.dart';
import 'package:new_petnurim_app/core/widgets/membership_card.dart';
import 'package:new_petnurim_app/core/widgets/my_info_card.dart';
import 'package:new_petnurim_app/core/widgets/my_info_row.dart';
import 'package:new_petnurim_app/core/widgets/mypage_name.dart';
import 'package:new_petnurim_app/core/widgets/nurim_text_card.dart';
import 'package:new_petnurim_app/core/widgets/page_header.dart';
import 'package:new_petnurim_app/core/widgets/popup_header.dart';
import 'package:new_petnurim_app/core/widgets/section_title.dart';

/// 화면 폭·글자 배율을 바꿔가며 공용 위젯의 오버플로를 검출한다.
/// 디자인이 375dp 기준 고정값으로 들어가 있어 좁은 화면/큰 글자에서 깨지는 곳을 찾는다.
void main() {
  const widths = <double>[320, 360, 412];
  const scales = <double>[1.0, 1.2, 1.3];
  final failures = <String>[];
  // 위젯별 (폭 -> 배율 -> 높이). 배율을 올려도 높이가 그대로면 글자가 박스 안에서 잘린다.
  final heights = <String, Map<String, double>>{};
  final rigid = <String>[];

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('Pretendard')
      ..addFont(rootBundle.load('assets/fonts/PretendardVariable.ttf'));
    await loader.load();
  });

  tearDownAll(() {
    // ignore: avoid_print
    print('\n================ 반응형 스윕 결과 ================');
    if (failures.isEmpty) {
      // ignore: avoid_print
      print('오버플로 없음');
    } else {
      for (final f in failures) {
        // ignore: avoid_print
        print(f);
      }
      // ignore: avoid_print
      print('총 ${failures.length} 건');
    }
    for (final e in heights.entries) {
      final h10 = e.value['360/1.0'];
      final h13 = e.value['360/1.3'];
      // 화면 높이(900)와 같으면 위젯이 세로로 꽉 차는 유형(AppBar/Dialog 등)이라
      // 이 방식으로는 측정 불가 — 제외한다.
      if (h10 != null &&
          h13 != null &&
          h10 < 890 &&
          (h13 - h10).abs() < 0.01) {
        rigid.add(
            '  ${e.key}  (360dp: 배율 1.0/1.3 모두 ${h10.toStringAsFixed(1)})');
      }
    }
    // ignore: avoid_print
    print('\n---- 글자 배율에 높이가 반응하지 않음(고정 높이 = 잘림 위험) ----');
    if (rigid.isEmpty) {
      // ignore: avoid_print
      print('없음');
    } else {
      for (final r in rigid) {
        // ignore: avoid_print
        print(r);
      }
      // ignore: avoid_print
      print('총 ${rigid.length} 건');
    }
    // ignore: avoid_print
    print('===============================================\n');
  });

  Future<void> sweep(
    WidgetTester tester,
    String name,
    Widget Function() build, {
    bool fullWidth = false,
  }) async {
    final probeKey = GlobalKey();
    for (final w in widths) {
      for (final s in scales) {
        await tester.binding.setSurfaceSize(Size(w, 900));
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: Size(w, 900),
              devicePixelRatio: 3.0,
              textScaler: const TextScaler.linear(1.0).clamp(
                minScaleFactor: s,
                maxScaleFactor: s,
              ),
            ),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(useMaterial3: true, fontFamily: 'Pretendard'),
              home: Scaffold(
                // heightFactor: 1 이라야 자식의 실제 높이를 잰다.
                // (Center 만 쓰면 세로로 늘어나 화면 높이 900 이 측정된다)
                body: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1.0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: fullWidth ? 0 : 16,
                    ),
                    child: KeyedSubtree(key: probeKey, child: build()),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final ex = tester.takeException();
        if (ex != null) {
          final msg = ex.toString().split('\n').first;
          failures.add('  ${w.toInt()}dp / x$s  $name\n      $msg');
        }
        final box = probeKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          heights.putIfAbsent(name, () => <String, double>{});
          heights[name]!['${w.toInt()}/$s'] = box.size.height;
        }
      }
    }
    await tester.binding.setSurfaceSize(null);
  }

  testWidgets('공용 위젯 반응형 스윕', (tester) async {
    // 홈 미션 카드 2개 나란히 — 실제 홈 레이아웃 재현
    await sweep(tester, '홈 미션 카드 2개(NurimCardBannerSmall)', () {
      Widget card(String a, String b, String status, String day, String? sfx) =>
          Expanded(
            child: NurimCardBannerSmall(
              width: double.infinity,
              titleLine1: a,
              titleLine2: b,
              pointText: '+100P',
              statusText: status,
              dayText: day,
              daySuffix: sfx,
            ),
          );
      return Row(
        children: [
          card('매일 출석하고', '포인트 받기', '연속 출석', '3일', null),
          const SizedBox(width: 12),
          card('마이펫 사진 찍고', '리워드 받기', '주간 참여', '3', ' / 7일'),
        ],
      );
    });

    await sweep(tester, 'NurimCardBanner', () => const NurimCardBanner(
          title: '마이 펫 사진 찍고',
          subtitle: '리워드 받기',
          pointText: '+100P',
          statusText: '주간 참여',
          dayText: '3 / 7일',
        ));

    await sweep(
        tester,
        'CalendarStamp(리워드)',
        () => const CalendarStamp(
            isAttended: true, showReward: true, showToday: true));

    await sweep(tester, 'NurimInfoRow', () => const NurimInfoRow(title: '휴대폰 번호'));
    await sweep(tester, 'NurimMyInfoRow',
        () => const NurimMyInfoRow(labelText: '결제 수단', primaryValue: '현대카드(1234)'));
    await sweep(tester, 'NurimListButton',
        () => const NurimListButton(title: '고객센터'));
    await sweep(tester, 'NurimMembershipCard',
        () => const NurimMembershipCard(
            tierName: '브론즈', nextBillingDate: '2026.10.04', monthlyFee: '9,900원'));
    await sweep(tester, 'NurimMyInfoCard',
        () => const NurimMyInfoCard(email: 'kakao_4979587618@temp.petnurim.kr'));
    await sweep(tester, 'NurimTextCard',
        () => const NurimTextCard(
            title: '펫누림 멤버십 결제가 완료되었어요',
            content: '이번 달 멤버십 혜택을 확인해 보세요.',
            date: '2026.09.04'));
    await sweep(tester, 'NurimAddressCard',
        () => const NurimAddressCard(
            title: '현재 주소', address: '서울 강남구 논현로85길 22 동경빌딩 12층'));
    await sweep(tester, 'NurimBottomActionBar',
        () => NurimBottomActionBar(primaryLabel: '확인', onPrimaryPressed: () {}),
        fullWidth: true);
    await sweep(tester, 'BullitText',
        () => const BullitText(text: '미션 수행 시 100P가 즉시 지급됩니다.'));
    await sweep(tester, 'NurimSectionTitle',
        () => const NurimSectionTitle(title: '기본 정보'));
    await sweep(tester, 'NurimMypageName',
        () => const NurimMypageName(name: '소지섭'));
    await sweep(tester, 'LastLoginBadge', () => const LastLoginBadge());
    await sweep(tester, 'NurimSelectableTab',
        () => NurimSelectableTab(label: '자주 묻는 질문', selected: true, onTap: () {}));
    await sweep(tester, 'PopupHeader', () => const PopupHeader(title: '주소 설정'),
        fullWidth: true);
    await sweep(tester, 'NurimPageHeader',
        () => const NurimPageHeader(title: '내 정보 관리'), fullWidth: true);
    await sweep(tester, 'CommonDialog',
        () => CommonDialog(
            title: '로그아웃하시겠어요?',
            content: '현재 계정에서 로그아웃됩니다.',
            cancelText: '취소',
            confirmText: '로그아웃',
            onConfirm: () {}));
    await sweep(tester, 'EdgeButtonDialog',
        () => EdgeButtonDialog(
            title: '주소가 저장되었습니다.', confirmText: '확인', onConfirm: () {}));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
