import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/event_models.dart';

abstract interface class EventRepository {
  /// 메인 이벤트 배너 목록 조회
  Future<EventBannersResponse> getBanners();
}

class BackendEventRepository implements EventRepository {
  const BackendEventRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<EventBannersResponse> getBanners() async {
    // 배너는 공개 엔드포인트일 수 있으므로 토큰이 있으면 전달하고, 없으면 그대로 호출한다.
    final token = await _tokenStorage.readAccessToken();
    final bearer =
        (token != null && token.trim().isNotEmpty) ? token.trim() : null;

    final payload = await _apiClient.getJson(
      '/api/v1/events/banners',
      bearerToken: bearer,
      fallbackMessage: '이벤트 배너를 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return EventBannersResponse.fromJson(payload);
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return BackendEventRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// 홈 화면 배너 목록 provider
final homeBannersProvider =
    FutureProvider.autoDispose<List<EventBanner>>((ref) async {
  final response = await ref.read(eventRepositoryProvider).getBanners();
  return response.homeBanners;
});
