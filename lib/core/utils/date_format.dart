String _pad2(int n) => n.toString().padLeft(2, '0');

/// 날짜 포맷 공통 확장.
///
/// 여러 화면에 `'${d.year}-${d.month...padLeft}-...'` 형태로 중복돼 있던
/// 날짜 포맷팅을 한 곳으로 모은다. 각 메서드의 출력은 기존 인라인 표현과 동일하다.
extension NurimDateFormat on DateTime {
  /// 백엔드 전송 포맷. 예) `2026-07-22`
  String toApiDate() => '$year-${_pad2(month)}-${_pad2(day)}';

  /// 한글 표기 포맷. 예) `2026년 07월 22일`
  String toKoreanDate() => '$year년 ${_pad2(month)}월 ${_pad2(day)}일';

  /// 점 구분 포맷.
  ///
  /// - `spaced` true: `2026. 07. 22`, false: `2026.07.22`
  /// - `trailing` true면 끝에 마침표 추가: `2026. 07. 22.`
  String toDotDate({bool spaced = true, bool trailing = false}) {
    final sep = spaced ? '. ' : '.';
    final base = '$year$sep${_pad2(month)}$sep${_pad2(day)}';
    return trailing ? '$base.' : base;
  }
}
