// 마이펫 촬영(PHOTO 이벤트) 도메인 모델
//
// - PhotoEventDetail       : GET /api/v1/user/events/photo/{eventMasterId}
// - PhotoEventPet          : GET /api/v1/user/events/photo/{eventMasterId}/pets
// - PhotoHistory           : GET /api/v1/user/events/photo/{eventMasterId}/pets/{petId}/history
// - PhotoParticipateResult : POST /api/v1/user/events/photo/{eventMasterId}/participate

int _parseInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// "/api/v1/files/{id}/download" 또는 "/api/v1/files/{id}/variant/thumb" 에서 fileId 추출
String? _fileIdFromUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  return RegExp(r'/files/(\d+)').firstMatch(url)?.group(1);
}

/// 이벤트 리워드 정보 (reward)
class PhotoEventReward {
  final String? rewardTypeCode;
  final String? rewardTypeName;
  final int rewardValue;

  const PhotoEventReward({
    this.rewardTypeCode,
    this.rewardTypeName,
    required this.rewardValue,
  });

  factory PhotoEventReward.fromJson(Map<String, dynamic> json) {
    return PhotoEventReward(
      rewardTypeCode: json['rewardTypeCode']?.toString(),
      rewardTypeName: json['rewardTypeName']?.toString(),
      rewardValue: _parseInt(json['rewardValue']),
    );
  }
}

/// 사진 이벤트 상세
class PhotoEventDetail {
  final String eventMasterId;
  final String eventTypeCode; // PHOTO
  final String title;
  final String? summary;
  final String? thumbnailImageUrl;
  final String? detailImageUrl;
  final String? startDt;
  final String? endDt;
  final String? eventPeriod;
  final String? noEndDateYn;
  final String progressStatus; // ONGOING / SCHEDULED / ENDED
  final String? guideContent;
  final String? photoMissionId;
  final String? missionCode;
  final String? missionTitle; // 예: "송곳니를 촬영해 주세요!"
  final String? missionGuide;
  final PhotoEventReward? reward;

  const PhotoEventDetail({
    required this.eventMasterId,
    required this.eventTypeCode,
    required this.title,
    this.summary,
    this.thumbnailImageUrl,
    this.detailImageUrl,
    this.startDt,
    this.endDt,
    this.eventPeriod,
    this.noEndDateYn,
    required this.progressStatus,
    this.guideContent,
    this.photoMissionId,
    this.missionCode,
    this.missionTitle,
    this.missionGuide,
    this.reward,
  });

  bool get isOngoing => progressStatus == 'ONGOING';
  int get rewardValue => reward?.rewardValue ?? 0;
  String? get thumbnailFileId => _fileIdFromUrl(thumbnailImageUrl);
  String? get detailImageFileId => _fileIdFromUrl(detailImageUrl);

  factory PhotoEventDetail.fromJson(Map<String, dynamic> json) {
    return PhotoEventDetail(
      eventMasterId: json['eventMasterId']?.toString() ?? '',
      eventTypeCode: json['eventTypeCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      thumbnailImageUrl: json['thumbnailImageUrl']?.toString(),
      detailImageUrl: json['detailImageUrl']?.toString(),
      startDt: json['startDt']?.toString(),
      endDt: json['endDt']?.toString(),
      eventPeriod: json['eventPeriod']?.toString(),
      noEndDateYn: json['noEndDateYn']?.toString(),
      progressStatus: json['progressStatus']?.toString() ?? '',
      guideContent: json['guideContent']?.toString(),
      photoMissionId: json['photoMissionId']?.toString(),
      missionCode: json['missionCode']?.toString(),
      missionTitle: json['missionTitle']?.toString(),
      missionGuide: json['missionGuide']?.toString(),
      reward: json['reward'] is Map<String, dynamic>
          ? PhotoEventReward.fromJson(json['reward'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 촬영 가능한 펫 1건
class PhotoEventPet {
  final String petId;
  final String petName;
  final String? thumbnailUrl;
  final String? breedName;
  final String? age;
  final String? gender;
  final String todayParticipatedYn; // Y/N

  const PhotoEventPet({
    required this.petId,
    required this.petName,
    this.thumbnailUrl,
    this.breedName,
    this.age,
    this.gender,
    required this.todayParticipatedYn,
  });

  bool get isTodayParticipated => todayParticipatedYn == 'Y';
  String? get thumbnailFileId => _fileIdFromUrl(thumbnailUrl);

  factory PhotoEventPet.fromJson(Map<String, dynamic> json) {
    return PhotoEventPet(
      petId: json['petId']?.toString() ?? '',
      petName: json['petName']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      breedName: json['breedName']?.toString(),
      age: json['age']?.toString(),
      gender: json['gender']?.toString(),
      todayParticipatedYn: json['todayParticipatedYn']?.toString() ?? 'N',
    );
  }
}

/// 촬영 내역의 펫 요약
class PhotoHistoryPet {
  final String petId;
  final String petName;
  final String? thumbnailUrl;

  const PhotoHistoryPet({
    required this.petId,
    required this.petName,
    this.thumbnailUrl,
  });

  String? get thumbnailFileId => _fileIdFromUrl(thumbnailUrl);

  factory PhotoHistoryPet.fromJson(Map<String, dynamic> json) {
    return PhotoHistoryPet(
      petId: json['petId']?.toString() ?? '',
      petName: json['petName']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
    );
  }
}

/// 촬영 이력 1건
class PhotoHistoryItem {
  final String participationId;
  final String participatedDt;
  final String? imageUrl;
  final int rewardValue;

  const PhotoHistoryItem({
    required this.participationId,
    required this.participatedDt,
    this.imageUrl,
    required this.rewardValue,
  });

  String? get imageFileId => _fileIdFromUrl(imageUrl);

  factory PhotoHistoryItem.fromJson(Map<String, dynamic> json) {
    return PhotoHistoryItem(
      participationId: json['participationId']?.toString() ?? '',
      participatedDt: json['participatedDt']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      rewardValue: _parseInt(json['rewardValue']),
    );
  }
}

/// 촬영 내역 응답
class PhotoHistory {
  final PhotoHistoryPet? pet;
  final int monthParticipationCount;
  final int totalReward;
  final List<PhotoHistoryItem> items;

  const PhotoHistory({
    this.pet,
    required this.monthParticipationCount,
    required this.totalReward,
    required this.items,
  });

  factory PhotoHistory.fromJson(Map<String, dynamic> json) {
    return PhotoHistory(
      pet: json['pet'] is Map<String, dynamic>
          ? PhotoHistoryPet.fromJson(json['pet'] as Map<String, dynamic>)
          : null,
      monthParticipationCount: _parseInt(json['monthParticipationCount']),
      totalReward: _parseInt(json['totalReward']),
      items: (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(PhotoHistoryItem.fromJson)
              .toList() ??
          const [],
    );
  }
}

/// 사진 저장(참여) 결과
class PhotoParticipateResult {
  final PhotoEventReward? reward;

  const PhotoParticipateResult({this.reward});

  int get rewardValue => reward?.rewardValue ?? 0;

  factory PhotoParticipateResult.fromJson(Map<String, dynamic> json) {
    return PhotoParticipateResult(
      reward: json['reward'] is Map<String, dynamic>
          ? PhotoEventReward.fromJson(json['reward'] as Map<String, dynamic>)
          : null,
    );
  }
}
