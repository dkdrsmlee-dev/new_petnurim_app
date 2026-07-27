// 출석 이벤트 관련 도메인 모델
//
// - AttendanceCurrentResponse : GET /api/v1/user/attendance/current
// - AttendanceCheckResponse   : POST /api/v1/user/attendance/current/check

int _parseInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// 현재 진행중 출석 이벤트 조회 응답
class AttendanceCurrentResponse {
  final String eventMasterId;
  final String title;
  final String? thumbnailFileId;
  final String? detailImageFileId;
  final String? detailImageUrl; // "/api/v1/files/{id}/download"
  final String eventPeriod;
  final String? startDt;
  final String? endDt;
  final String? noEndDateYn;
  final String? guideContent;
  final String todayAttendanceYn;
  final int continuousAttendanceDays;
  final int totalAttendanceDays;
  final int currentMonthAttendanceDays;
  final List<AttendanceCalendarDay> attendanceCalendar;
  final List<ContinuousReward> continuousRewards;
  final String? shareTitle;
  final String? sharePeriod;
  final String? notice;

  const AttendanceCurrentResponse({
    required this.eventMasterId,
    required this.title,
    this.thumbnailFileId,
    this.detailImageFileId,
    this.detailImageUrl,
    required this.eventPeriod,
    this.startDt,
    this.endDt,
    this.noEndDateYn,
    this.guideContent,
    required this.todayAttendanceYn,
    required this.continuousAttendanceDays,
    required this.totalAttendanceDays,
    required this.currentMonthAttendanceDays,
    required this.attendanceCalendar,
    required this.continuousRewards,
    this.shareTitle,
    this.sharePeriod,
    this.notice,
  });

  bool get isTodayAttended => todayAttendanceYn == 'Y';

  /// 상세 배너 이미지 fileId (detailImageFileId 우선, 없으면 detailImageUrl에서 추출)
  String? get detailImageFileIdResolved {
    if (detailImageFileId != null && detailImageFileId!.isNotEmpty) {
      return detailImageFileId;
    }
    final url = detailImageUrl;
    if (url == null || url.isEmpty) return null;
    return RegExp(r'/files/(\d+)/download').firstMatch(url)?.group(1);
  }

  factory AttendanceCurrentResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceCurrentResponse(
      eventMasterId: json['eventMasterId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      thumbnailFileId: json['thumbnailFileId']?.toString(),
      detailImageFileId: json['detailImageFileId']?.toString(),
      detailImageUrl: json['detailImageUrl']?.toString(),
      eventPeriod: json['eventPeriod']?.toString() ?? '',
      startDt: json['startDt']?.toString(),
      endDt: json['endDt']?.toString(),
      noEndDateYn: json['noEndDateYn']?.toString(),
      guideContent: json['guideContent']?.toString(),
      todayAttendanceYn: json['todayAttendanceYn']?.toString() ?? 'N',
      continuousAttendanceDays: _parseInt(json['continuousAttendanceDays']),
      totalAttendanceDays: _parseInt(json['totalAttendanceDays']),
      currentMonthAttendanceDays: _parseInt(json['currentMonthAttendanceDays']),
      attendanceCalendar: (json['attendanceCalendar'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AttendanceCalendarDay.fromJson)
              .toList() ??
          const [],
      continuousRewards: (json['continuousRewards'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ContinuousReward.fromJson)
              .toList() ??
          const [],
      shareTitle: json['shareTitle']?.toString(),
      sharePeriod: json['sharePeriod']?.toString(),
      notice: json['notice']?.toString(),
    );
  }
}

/// 출석 달력의 하루
class AttendanceCalendarDay {
  final String attendanceDate; // YYYY-MM-DD
  final String attendanceYn; // Y/N
  final String? rewardAmt;

  const AttendanceCalendarDay({
    required this.attendanceDate,
    required this.attendanceYn,
    this.rewardAmt,
  });

  bool get isAttended => attendanceYn == 'Y';

  /// attendanceDate(YYYY-MM-DD)를 DateTime으로 파싱 (실패 시 null)
  DateTime? get date => DateTime.tryParse(attendanceDate);

  factory AttendanceCalendarDay.fromJson(Map<String, dynamic> json) {
    return AttendanceCalendarDay(
      attendanceDate: json['attendanceDate']?.toString() ?? '',
      attendanceYn: json['attendanceYn']?.toString() ?? 'N',
      rewardAmt: json['rewardAmt']?.toString(),
    );
  }
}

/// 연속 출석 리워드 마일스톤
class ContinuousReward {
  final int continuousDay;
  final String rewardAmt;
  final String receivedYn; // Y/N

  const ContinuousReward({
    required this.continuousDay,
    required this.rewardAmt,
    required this.receivedYn,
  });

  bool get isReceived => receivedYn == 'Y';

  /// rewardAmt("100" 또는 "100.00")를 정수 포인트로 변환
  int get rewardPoints => (double.tryParse(rewardAmt) ?? 0).toInt();

  factory ContinuousReward.fromJson(Map<String, dynamic> json) {
    return ContinuousReward(
      continuousDay: _parseInt(json['continuousDay']),
      rewardAmt: json['rewardAmt']?.toString() ?? '0',
      receivedYn: json['receivedYn']?.toString() ?? 'N',
    );
  }
}

/// 오늘 출석 응답
class AttendanceCheckResponse {
  final String todayAttendanceYn;
  final int continuousAttendanceDays;
  final int currentMonthAttendanceDays;
  final int totalAttendanceDays;
  final String baseRewardAmt;
  final String continuousRewardAmt;
  final String totalRewardAmt;
  final String rewardYn;

  const AttendanceCheckResponse({
    required this.todayAttendanceYn,
    required this.continuousAttendanceDays,
    required this.currentMonthAttendanceDays,
    required this.totalAttendanceDays,
    required this.baseRewardAmt,
    required this.continuousRewardAmt,
    required this.totalRewardAmt,
    required this.rewardYn,
  });

  bool get isRewardGranted => rewardYn == 'Y';

  /// totalRewardAmt("300" 또는 "300.00")를 정수 포인트로 변환
  int get totalRewardPoints => (double.tryParse(totalRewardAmt) ?? 0).toInt();

  factory AttendanceCheckResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceCheckResponse(
      todayAttendanceYn: json['todayAttendanceYn']?.toString() ?? 'N',
      continuousAttendanceDays: _parseInt(json['continuousAttendanceDays']),
      currentMonthAttendanceDays: _parseInt(json['currentMonthAttendanceDays']),
      totalAttendanceDays: _parseInt(json['totalAttendanceDays']),
      baseRewardAmt: json['baseRewardAmt']?.toString() ?? '0',
      continuousRewardAmt: json['continuousRewardAmt']?.toString() ?? '0',
      totalRewardAmt: json['totalRewardAmt']?.toString() ?? '0',
      rewardYn: json['rewardYn']?.toString() ?? 'N',
    );
  }
}
