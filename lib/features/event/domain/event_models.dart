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
