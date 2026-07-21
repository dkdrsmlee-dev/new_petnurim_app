/// JSON(Map · 동적 값) 파싱 공통 유틸.
///
/// 여러 도메인 모델과 API 계층에 중복 구현돼 있던 `_readString`/`_readInt`/
/// `_readBool` 파싱 규칙을 하나로 모은다. 각 호출부는 자신에게 필요한 기본값/
/// 제어 흐름만 남긴 얇은 래퍼로 이 유틸을 위임 호출한다.
abstract final class JsonReader {
  /// 문자열이면 trim(빈 문자열은 무효), 숫자/불리언이면 문자열로 변환. 그 외 null.
  static String? coerceString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    } else if (value is num || value is bool) {
      return '$value';
    }
    return null;
  }

  /// Map에서 [keys]를 순서대로 시도해 첫 유효 문자열을 반환([coerceString] 규칙).
  static String? stringFrom(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = coerceString(map[key]);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  /// 비어있지 않은 문자열이면 trim, 그 외(숫자·불리언 변환 안 함)에는 null.
  static String? plainString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  /// [payload]가 Map일 때만 [key]로 조회하여 [plainString] 규칙을 적용.
  static String? plainStringFrom(Object? payload, String key) {
    if (payload is! Map) {
      return null;
    }
    return plainString(payload[key]);
  }

  /// 정수 강제 변환. int/num/문자열 파싱, 실패 시 [fallback].
  static int asInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  /// 불리언 강제 변환.
  ///
  /// bool → 그대로, 숫자 → 0이 아니면 true, 문자열 → `true/1/y/yes`는 true,
  /// `false/0/n/no`는 false. 인식할 수 없으면 null.
  static bool? coerceBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (const {'true', '1', 'y', 'yes'}.contains(normalized)) {
        return true;
      }
      if (const {'false', '0', 'n', 'no'}.contains(normalized)) {
        return false;
      }
    }
    return null;
  }

  /// Map에서 [keys]를 순서대로 시도해 첫 유효 불리언을 반환([coerceBool] 규칙).
  static bool? boolFrom(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = coerceBool(map[key]);
      if (value != null) {
        return value;
      }
    }
    return null;
  }
}
