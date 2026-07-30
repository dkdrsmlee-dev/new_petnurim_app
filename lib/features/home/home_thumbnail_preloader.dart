import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/widgets/authed_file_image.dart';
import '../event/data/event_repository.dart';

/// 홈 화면 리워드 카드 썸네일(출석/촬영 이벤트)을 백그라운드로 미리 받아
/// 전역 ImageCache 에 적재한다. 스플래시 동안 **논블로킹**으로 호출하면,
/// 홈 진입 시 캐시 히트로 썸네일이 자연스럽게(깜빡임 없이) 표시된다.
///
/// 홈의 `_rewardThumb` 와 **동일한 파라미터**(variant `'thumb'`, downloadFallback
/// `true`, scale 1.0)로 로드해야 캐시 키가 일치한다.
///
/// best-effort: 실패해도 홈은 정상 동작(기존처럼 폴백/지연 로드)한다.
Future<void> precacheHomeThumbnails(WidgetRef ref) async {
  // 의존성은 async gap 이전에 읽어둔다(스플래시가 먼저 unmount 될 수 있으므로).
  final EventRepository repository = ref.read(eventRepositoryProvider);
  final ApiClient apiClient = ref.read(apiClientProvider);
  final TokenStorage tokenStorage = ref.read(tokenStorageProvider);

  try {
    final templates = await repository.getTemplates();

    final fileIds = <String>{};
    final attendanceId = templates.attendance?.thumbnailFileId;
    final photoId = templates.photo?.thumbnailFileId;
    if (attendanceId != null && attendanceId.isNotEmpty) fileIds.add(attendanceId);
    if (photoId != null && photoId.isNotEmpty) fileIds.add(photoId);

    for (final fileId in fileIds) {
      _warmImageCache(
        AuthedFileImage(
          fileId,
          apiClient: apiClient,
          tokenStorage: tokenStorage,
          variant: 'thumb',
          downloadFallback: true,
        ),
      );
    }
  } catch (_) {
    // 프리로드 실패는 무시(홈 진입에는 영향 없음).
  }
}

/// BuildContext 없이 ImageProvider 를 해석해 ImageCache 를 워밍한다.
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
