import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 미션 완료 → 홈 수치 재조정용 신호/override 프로바이더.
///
/// 홈의 "연속 출석"·"주간 참여" 수치는 `/events/templates` 집계에서 오는데,
/// 이 집계가 방금 완료한 출석/촬영을 **곧바로 반영하지 못하는 지연**이 있다
/// (write 직후 자동 재조회 시점엔 아직 이전 값이 내려옴 → 새로고침해야 갱신).
///
/// 이를 앱에서 흡수하기 위한 조합:
/// - ① 완료 응답이 준 **확정값**(출석: `continuousAttendanceDays`) 또는
///   **낙관적 +1**(촬영: 참여횟수)을 [homeMissionOverrideProvider]로 즉시 표시
/// - ③ `/events/templates`가 그 목표값에 도달할 때까지 짧게 폴링한 뒤 override 해제
///   (수렴하면 실제 집계값을 보여주고, 지연이 길어도 사용자는 확정값을 계속 봄)
class HomeMissionOverride {
  /// 홈 "연속 출석" 표시 override. null이면 templates 값을 그대로 사용.
  final int? attendanceDays;

  /// 홈 "주간 참여" 표시 override. null이면 templates 값을 그대로 사용.
  final int? participationCount;

  const HomeMissionOverride({this.attendanceDays, this.participationCount});
}

/// 출석 완료 신호: 출석한 펫 id + 그 펫의 최신 연속출석일수(확정값).
///
/// 홈 카드의 "연속 출석"은 **대표펫 기준**이라, 홈이 이 신호를 소비할 때
/// `petId`가 대표펫과 일치할 때만 override를 적용한다(불일치 시 홈 수치 불변).
typedef AttendanceCheckSignal = ({String petId, int continuousAttendanceDays});

class AttendanceCheckResultNotifier extends Notifier<AttendanceCheckSignal?> {
  @override
  AttendanceCheckSignal? build() => null;

  void set(AttendanceCheckSignal? value) => state = value;
}

final attendanceCheckResultProvider =
    NotifierProvider<AttendanceCheckResultNotifier, AttendanceCheckSignal?>(
  AttendanceCheckResultNotifier.new,
);

/// 촬영 참여 성공 신호: 참여한 펫 id(없으면 null).
///
/// 홈 "주간 참여"도 **대표펫 기준**이라, 홈은 이 `petId`가 대표펫과 일치할
/// 때만 override(+1)를 적용한다. 홈이 소비한 뒤 null로 리셋한다.
class PhotoParticipatedNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final photoParticipatedProvider =
    NotifierProvider<PhotoParticipatedNotifier, String?>(
  PhotoParticipatedNotifier.new,
);

/// 홈 미션 카드 표시값 override(①+③ 재조정용). 기본은 override 없음.
class HomeMissionOverrideNotifier extends Notifier<HomeMissionOverride> {
  @override
  HomeMissionOverride build() => const HomeMissionOverride();

  void set(HomeMissionOverride value) => state = value;
}

final homeMissionOverrideProvider =
    NotifierProvider<HomeMissionOverrideNotifier, HomeMissionOverride>(
  HomeMissionOverrideNotifier.new,
);
