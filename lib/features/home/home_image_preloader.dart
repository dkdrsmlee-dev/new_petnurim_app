import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/widgets/authed_file_image.dart';
import '../attendance/data/attendance_repository.dart';
import '../camera/data/photo_event_repository.dart';
import '../event/data/event_repository.dart';

/// 홈 화면에서 쓰는 이미지를 백그라운드로 미리 받아 캐시(디스크+전역 ImageCache)에
/// 적재한다. 진입 시 캐시 히트로 **빈 화면→팝인 없이** 즉시 표시된다.
///
/// 대상 3종:
/// 1. 이벤트 캐러셀 배너(`homeBanners`) — 절대 URL 은 NetworkImage, 아니면 fileId 원본
/// 2. 리워드 카드 썸네일(출석/촬영 `thumbnailFileId`) — `_rewardThumb` 와 동일한
///    파라미터(variant `'thumb'`, downloadFallback `true`)로 로드해야 캐시 키 일치
/// 3. 출석/촬영 상세 배너 이미지(detail) — 각 화면과 동일한 `medium` variant
///
/// 스플래시(토큰복원 콜드 진입)와 홈 진입(신규 로그인/새로고침) 양쪽에서 호출되어
/// 모든 경로를 커버한다. 전부 **논블로킹·best-effort**(실패해도 화면은 정상 동작).
Future<void> prewarmHomeImages({
  required EventRepository eventRepository,
  required AttendanceRepository attendanceRepository,
  required PhotoEventRepository photoEventRepository,
  required ApiClient apiClient,
  required TokenStorage tokenStorage,
}) async {
  AuthedFileImage authed(
    String fileId, {
    String? variant,
    bool downloadFallback = false,
  }) {
    return AuthedFileImage(
      fileId,
      apiClient: apiClient,
      tokenStorage: tokenStorage,
      variant: variant,
      downloadFallback: downloadFallback,
    );
  }

  // 1) 이벤트 캐러셀 배너
  try {
    final banners = (await eventRepository.getBanners()).homeBanners;
    for (final banner in banners) {
      final file = banner.bannerFile;
      if (file == null) continue;
      final url = file.fileUrl;
      if (url != null &&
          (url.startsWith('http://') || url.startsWith('https://'))) {
        _warmImageCache(NetworkImage(url));
      } else {
        final id = file.fileId;
        // 캐러셀과 동일하게 medium(+원본 폴백)으로 워밍해 캐시 키를 일치시킨다.
        if (id != null && id.isNotEmpty) {
          _warmImageCache(authed(id, variant: 'medium', downloadFallback: true));
        }
      }
    }
  } catch (_) {
    // 배너 프리워밍 실패는 무시.
  }

  // 2) 리워드 카드 썸네일 + 3) 출석/촬영 상세 이미지
  try {
    final templates = await eventRepository.getTemplates();

    // 2) 리워드 카드 썸네일 (thumb, 없으면 원본 폴백)
    for (final fileId in <String?>{
      templates.attendance?.thumbnailFileId,
      templates.photo?.thumbnailFileId,
    }) {
      if (fileId != null && fileId.isNotEmpty) {
        _warmImageCache(authed(fileId, variant: 'thumb', downloadFallback: true));
      }
    }

    // 3-a) 출석 상세 배너 이미지 (medium, 없으면 원본 폴백)
    final attendance = templates.attendance;
    if (attendance != null && attendance.eventMasterId.isNotEmpty) {
      try {
        final detail =
            await attendanceRepository.getAttendance(attendance.eventMasterId);
        final id = detail.detailImageFileIdResolved;
        if (id != null && id.isNotEmpty) {
          _warmImageCache(authed(id, variant: 'medium', downloadFallback: true));
        }
      } catch (_) {
        // 출석 상세 프리워밍 실패는 무시.
      }
    }

    // 3-b) 촬영 가이드(촬영예시) 상세 이미지 (medium)
    final photo = templates.photo;
    if (photo != null && photo.eventMasterId.isNotEmpty) {
      try {
        final detail =
            await photoEventRepository.getDetail(photo.eventMasterId);
        final id = detail.detailImageFileId;
        if (id != null && id.isNotEmpty) {
          _warmImageCache(authed(id, variant: 'medium'));
        }
      } catch (_) {
        // 촬영 상세 프리워밍 실패는 무시.
      }
    }
  } catch (_) {
    // 템플릿 조회 실패는 무시.
  }
}

/// 스플래시에서 호출: 홈 이미지 프리워밍(논블로킹, best-effort).
Future<void> precacheHomeImages(WidgetRef ref) {
  return prewarmHomeImages(
    eventRepository: ref.read(eventRepositoryProvider),
    attendanceRepository: ref.read(attendanceRepositoryProvider),
    photoEventRepository: ref.read(photoEventRepositoryProvider),
    apiClient: ref.read(apiClientProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
}

/// 홈 진입 시 호출용 provider(신규 로그인/새로고침 경로 커버).
/// `ref.watch(homeImagePrewarmProvider)` 한 번으로 발동한다.
final homeImagePrewarmProvider = FutureProvider.autoDispose<void>((ref) async {
  await prewarmHomeImages(
    eventRepository: ref.read(eventRepositoryProvider),
    attendanceRepository: ref.read(attendanceRepositoryProvider),
    photoEventRepository: ref.read(photoEventRepositoryProvider),
    apiClient: ref.read(apiClientProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

/// BuildContext 없이 ImageProvider 를 해석해 캐시를 워밍한다.
/// (AuthedFileImage 의 캐시 키는 ImageConfiguration 과 무관하므로 empty 사용)
void _warmImageCache(ImageProvider provider) {
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (image, _) => stream.removeListener(listener),
    onError: (Object error, StackTrace? stack) =>
        stream.removeListener(listener),
  );
  stream.addListener(listener);
}
