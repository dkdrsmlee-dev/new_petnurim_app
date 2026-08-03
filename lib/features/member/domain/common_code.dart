/// 백엔드 공통코드 항목 (common-codes).
///
/// 그룹키별 코드 목록의 개별 항목. codeVal(코드값)로 제출하고 codeNm(코드명)을 표시한다.
class CommonCode {
  const CommonCode({
    required this.codeVal,
    required this.codeNm,
    this.sortNo = 0,
  });

  final String codeVal;
  final String codeNm;
  final int sortNo;

  /// 응답 필드명이 명세에 명확치 않아 여러 후보 키를 방어적으로 읽는다.
  factory CommonCode.fromJson(Map<String, dynamic> json) {
    String? read(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return null;
    }

    return CommonCode(
      codeVal: read(['codeVal', 'codeValue', 'code', 'value']) ?? '',
      codeNm: read(['codeNm', 'codeName', 'name', 'label']) ?? '',
      sortNo: int.tryParse(read(['sortNo', 'sortOrder', 'sort', 'order']) ?? '') ?? 0,
    );
  }
}
