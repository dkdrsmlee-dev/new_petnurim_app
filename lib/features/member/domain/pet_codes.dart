// 펫 관련 공통코드(성별/펫종류/Y·N) 매핑을 한 곳에서 관리하는 유틸.
//
// 백엔드 common-codes(GENDER, PET_TYPE 등)에 대응한다.
// 표시 라벨은 서버 응답의 코드명(genderCodeNm 등)을 우선 사용하고,
// label()은 서버값이 없을 때의 fallback 및 입력 선택지 구성에 쓴다.

/// 코드값-라벨 쌍 (입력 선택지 구성용)
class PetCodeOption {
  const PetCodeOption(this.code, this.label);

  final String code;
  final String label;
}

/// 성별 공통코드 (GENDER)
class PetGender {
  const PetGender._();

  static const String male = 'MALE';
  static const String female = 'FEMALE';

  /// 성별 라벨. 서버 코드명([serverName])이 있으면 그대로 사용하고,
  /// 없을 때만 코드값으로 매핑한다.
  static String label(String? code, {String? serverName}) {
    if (serverName != null && serverName.isNotEmpty) return serverName;
    switch (code) {
      case male:
        return '남아';
      case female:
        return '여아';
      default:
        return '-';
    }
  }

  /// 입력 선택지 (성별 토글용)
  static const List<PetCodeOption> options = [
    PetCodeOption(male, '남아'),
    PetCodeOption(female, '여아'),
  ];
}

/// 펫 종류 공통코드 (PET_TYPE)
class PetType {
  const PetType._();

  static const String dog = 'DOG';
  static const String cat = 'CAT';

  /// 펫 종류 라벨. 서버 코드명([serverName])이 있으면 그대로 사용한다.
  static String label(String? code, {String? serverName}) {
    if (serverName != null && serverName.isNotEmpty) return serverName;
    switch (code) {
      case dog:
        return '강아지';
      case cat:
        return '고양이';
      default:
        return '-';
    }
  }

  /// 입력 선택지 (펫 종류 선택용)
  static const List<PetCodeOption> options = [
    PetCodeOption(dog, '강아지'),
    PetCodeOption(cat, '고양이'),
  ];
}

/// Y/N 공통코드 헬퍼
class YesNo {
  const YesNo._();

  static const String yes = 'Y';
  static const String no = 'N';

  static bool isYes(String? value) => value == yes;

  static String from(bool value) => value ? yes : no;
}
