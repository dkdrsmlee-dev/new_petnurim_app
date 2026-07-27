// 이벤트 관련 도메인 모델
//
// - EventBannersResponse : GET /api/v1/events/banners

/// 배너 이미지 파일 정보
class BannerFile {
  final String? fileId;
  final String? fileUrl;

  const BannerFile({this.fileId, this.fileUrl});

  factory BannerFile.fromJson(Map<String, dynamic> json) {
    return BannerFile(
      fileId: json['fileId']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
    );
  }
}

/// 이벤트 배너 1건
class EventBanner {
  final String eventMasterId;
  final String eventName;
  final BannerFile? bannerFile;

  const EventBanner({
    required this.eventMasterId,
    required this.eventName,
    this.bannerFile,
  });

  factory EventBanner.fromJson(Map<String, dynamic> json) {
    final bf = json['bannerFile'];
    return EventBanner(
      eventMasterId: json['eventMasterId']?.toString() ?? '',
      eventName: json['eventName']?.toString() ?? '',
      bannerFile: bf is Map<String, dynamic> ? BannerFile.fromJson(bf) : null,
    );
  }
}

/// 메인 이벤트 배너 목록 응답 (홈/이벤트 배너 구분)
class EventBannersResponse {
  final List<EventBanner> homeBanners;
  final List<EventBanner> eventBanners;

  const EventBannersResponse({
    required this.homeBanners,
    required this.eventBanners,
  });

  factory EventBannersResponse.fromJson(Map<String, dynamic> json) {
    return EventBannersResponse(
      homeBanners: _parseList(json['homeBanners']),
      eventBanners: _parseList(json['eventBanners']),
    );
  }

  static List<EventBanner> _parseList(dynamic value) {
    return (value as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(EventBanner.fromJson)
            .toList() ??
        const [];
  }
}

int _parseInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// 이벤트 기본 리워드
class DefaultReward {
  final String? rewardTypeCode; // POINT 등
  final String? rewardTypeName;
  final int rewardValue;

  const DefaultReward({
    this.rewardTypeCode,
    this.rewardTypeName,
    required this.rewardValue,
  });

  factory DefaultReward.fromJson(Map<String, dynamic> json) {
    return DefaultReward(
      rewardTypeCode: json['rewardTypeCode']?.toString(),
      rewardTypeName: json['rewardTypeName']?.toString(),
      rewardValue: _parseInt(json['rewardValue']),
    );
  }
}

/// 메인 이벤트 템플릿 1건 (출석/사진 등)
class EventTemplate {
  final String eventMasterId;
  final String eventTypeCode; // ATTENDANCE / PHOTO / ...
  final String title;
  final String? summary;
  final String? thumbnailImageUrl; // "/api/v1/files/{id}/download"
  final String? startDt;
  final String? endDt;
  final String? noEndDateYn;
  final String progressStatus; // ONGOING / SCHEDULED / ENDED
  final int continuousAttendanceDays;
  final DefaultReward? defaultReward;

  const EventTemplate({
    required this.eventMasterId,
    required this.eventTypeCode,
    required this.title,
    this.summary,
    this.thumbnailImageUrl,
    this.startDt,
    this.endDt,
    this.noEndDateYn,
    required this.progressStatus,
    required this.continuousAttendanceDays,
    this.defaultReward,
  });

  bool get isOngoing => progressStatus == 'ONGOING';

  /// thumbnailImageUrl("/api/v1/files/138/download")에서 fileId(138) 추출
  String? get thumbnailFileId {
    final url = thumbnailImageUrl;
    if (url == null || url.isEmpty) return null;
    final match = RegExp(r'/files/(\d+)/download').firstMatch(url);
    return match?.group(1);
  }

  factory EventTemplate.fromJson(Map<String, dynamic> json) {
    return EventTemplate(
      eventMasterId: json['eventMasterId']?.toString() ?? '',
      eventTypeCode: json['eventTypeCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      thumbnailImageUrl: json['thumbnailImageUrl']?.toString(),
      startDt: json['startDt']?.toString(),
      endDt: json['endDt']?.toString(),
      noEndDateYn: json['noEndDateYn']?.toString(),
      progressStatus: json['progressStatus']?.toString() ?? '',
      continuousAttendanceDays: _parseInt(json['continuousAttendanceDays']),
      defaultReward: json['defaultReward'] is Map<String, dynamic>
          ? DefaultReward.fromJson(json['defaultReward'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 메인 이벤트 템플릿 목록 응답 (타입별 객체: { ATTENDANCE: {...}, PHOTO: {...} })
class EventTemplates {
  final EventTemplate? attendance;
  final EventTemplate? photo;

  const EventTemplates({this.attendance, this.photo});

  factory EventTemplates.fromJson(Map<String, dynamic> json) {
    EventTemplate? parse(dynamic value) =>
        value is Map<String, dynamic> ? EventTemplate.fromJson(value) : null;
    return EventTemplates(
      attendance: parse(json['ATTENDANCE']),
      photo: parse(json['PHOTO']),
    );
  }
}
