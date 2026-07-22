import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/utils/date_format.dart';

void main() {
  final d = DateTime(2026, 7, 22);

  test('toApiDate → yyyy-MM-dd (zero-padded)', () {
    expect(d.toApiDate(), '2026-07-22');
    expect(DateTime(2026, 12, 5).toApiDate(), '2026-12-05');
  });

  test('toKoreanDate → yyyy년 MM월 dd일', () {
    expect(d.toKoreanDate(), '2026년 07월 22일');
  });

  test('toDotDate 기본(spaced) → "yyyy. MM. dd"', () {
    expect(d.toDotDate(), '2026. 07. 22');
  });

  test('toDotDate(spaced: false) → "yyyy.MM.dd"', () {
    expect(d.toDotDate(spaced: false), '2026.07.22');
  });

  test('toDotDate(trailing: true) → 끝에 마침표', () {
    expect(d.toDotDate(trailing: true), '2026. 07. 22.');
  });
}
