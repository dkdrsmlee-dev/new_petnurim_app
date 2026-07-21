import 'package:flutter_test/flutter_test.dart';
import 'package:new_petnurim_app/core/utils/json_reader.dart';

void main() {
  group('JsonReader.coerceString', () {
    test('문자열은 trim하여 반환한다', () {
      expect(JsonReader.coerceString('  hello  '), 'hello');
    });

    test('빈 문자열/공백만 있으면 null', () {
      expect(JsonReader.coerceString(''), isNull);
      expect(JsonReader.coerceString('   '), isNull);
    });

    test('숫자/불리언은 문자열로 변환한다', () {
      expect(JsonReader.coerceString(10), '10');
      expect(JsonReader.coerceString(3.5), '3.5');
      expect(JsonReader.coerceString(true), 'true');
    });

    test('null 및 그 외 타입은 null', () {
      expect(JsonReader.coerceString(null), isNull);
      expect(JsonReader.coerceString({'a': 1}), isNull);
    });
  });

  group('JsonReader.stringFrom', () {
    test('여러 키 중 첫 유효값을 반환한다', () {
      final map = {'a': '', 'b': 'value', 'c': 'other'};
      expect(JsonReader.stringFrom(map, ['a', 'b', 'c']), 'value');
    });

    test('유효값이 없으면 null', () {
      expect(JsonReader.stringFrom({'a': '', 'b': null}, ['a', 'b']), isNull);
    });

    test('숫자 값도 문자열로 변환해 반환한다', () {
      expect(JsonReader.stringFrom({'n': 7}, ['n']), '7');
    });
  });

  group('JsonReader.plainString', () {
    test('비어있지 않은 문자열만 trim하여 반환한다', () {
      expect(JsonReader.plainString('  hi '), 'hi');
    });

    test('숫자/불리언은 변환하지 않고 null', () {
      expect(JsonReader.plainString(10), isNull);
      expect(JsonReader.plainString(true), isNull);
    });

    test('빈 문자열/null은 null', () {
      expect(JsonReader.plainString(''), isNull);
      expect(JsonReader.plainString(null), isNull);
    });
  });

  group('JsonReader.plainStringFrom', () {
    test('Map이면 키로 조회하여 plainString 규칙 적용', () {
      expect(JsonReader.plainStringFrom({'code': ' A '}, 'code'), 'A');
      expect(JsonReader.plainStringFrom({'n': 1}, 'n'), isNull);
    });

    test('Map이 아니면 null', () {
      expect(JsonReader.plainStringFrom('not a map', 'code'), isNull);
      expect(JsonReader.plainStringFrom(null, 'code'), isNull);
    });
  });

  group('JsonReader.asInt', () {
    test('int/num/문자열을 정수로 변환한다', () {
      expect(JsonReader.asInt(5), 5);
      expect(JsonReader.asInt(3.9), 3);
      expect(JsonReader.asInt('42'), 42);
      expect(JsonReader.asInt(' 7 '), 7);
    });

    test('변환 실패 시 fallback(기본 0)', () {
      expect(JsonReader.asInt('abc'), 0);
      expect(JsonReader.asInt(null), 0);
      expect(JsonReader.asInt('abc', fallback: -1), -1);
    });
  });

  group('JsonReader.coerceBool', () {
    test('bool은 그대로', () {
      expect(JsonReader.coerceBool(true), isTrue);
      expect(JsonReader.coerceBool(false), isFalse);
    });

    test('숫자는 0 여부로 판단', () {
      expect(JsonReader.coerceBool(1), isTrue);
      expect(JsonReader.coerceBool(0), isFalse);
    });

    test('문자열 true/1/y/yes → true, false/0/n/no → false', () {
      for (final v in ['true', '1', 'Y', 'YES', ' yes ']) {
        expect(JsonReader.coerceBool(v), isTrue, reason: v);
      }
      for (final v in ['false', '0', 'N', 'no']) {
        expect(JsonReader.coerceBool(v), isFalse, reason: v);
      }
    });

    test('인식할 수 없으면 null', () {
      expect(JsonReader.coerceBool('maybe'), isNull);
      expect(JsonReader.coerceBool(null), isNull);
    });
  });

  group('JsonReader.boolFrom', () {
    test('여러 키 중 첫 유효 불리언을 반환한다', () {
      expect(JsonReader.boolFrom({'a': 'x', 'b': 'yes'}, ['a', 'b']), isTrue);
    });

    test('유효값이 없으면 null', () {
      expect(JsonReader.boolFrom({'a': 'x'}, ['a']), isNull);
    });
  });
}
