import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/photo_event_models.dart';

abstract interface class PhotoEventRepository {
  /// 사진 이벤트 상세 조회
  Future<PhotoEventDetail> getDetail(String eventMasterId);

  /// 촬영 가능한 펫 목록 조회
  Future<List<PhotoEventPet>> getPets(String eventMasterId);

  /// 특정 펫의 촬영 내역 조회
  Future<PhotoHistory> getPetHistory(String eventMasterId, String petId);

  /// 사진 저장(참여)
  Future<PhotoParticipateResult> participate({
    required String eventMasterId,
    required String petId,
    required String fileId,
  });
}

class BackendPhotoEventRepository implements PhotoEventRepository {
  const BackendPhotoEventRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<PhotoEventDetail> getDetail(String eventMasterId) async {
    final payload = await _apiClient.getJson(
      '/api/v1/user/events/photo/$eventMasterId',
      bearerToken: await _readAccessToken('로그인 정보가 없어 이벤트 정보를 조회할 수 없습니다.'),
      fallbackMessage: '이벤트 정보를 불러오지 못했습니다.',
    );
    if (payload is Map<String, dynamic>) {
      return PhotoEventDetail.fromJson(payload);
    }
    throw const FormatException('잘못된 응답 형식입니다.');
  }

  @override
  Future<List<PhotoEventPet>> getPets(String eventMasterId) async {
    final payload = await _apiClient.getJson(
      '/api/v1/user/events/photo/$eventMasterId/pets',
      bearerToken: await _readAccessToken('로그인 정보가 없어 펫 목록을 조회할 수 없습니다.'),
      fallbackMessage: '펫 목록을 불러오지 못했습니다.',
    );
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(PhotoEventPet.fromJson)
          .toList();
    }
    throw const FormatException('잘못된 응답 형식입니다.');
  }

  @override
  Future<PhotoHistory> getPetHistory(String eventMasterId, String petId) async {
    final payload = await _apiClient.getJson(
      '/api/v1/user/events/photo/$eventMasterId/pets/$petId/history',
      bearerToken: await _readAccessToken('로그인 정보가 없어 촬영 내역을 조회할 수 없습니다.'),
      fallbackMessage: '촬영 내역을 불러오지 못했습니다.',
    );
    if (payload is Map<String, dynamic>) {
      return PhotoHistory.fromJson(payload);
    }
    throw const FormatException('잘못된 응답 형식입니다.');
  }

  @override
  Future<PhotoParticipateResult> participate({
    required String eventMasterId,
    required String petId,
    required String fileId,
  }) async {
    final payload = await _apiClient.postJson(
      '/api/v1/user/events/photo/$eventMasterId/participate',
      body: {'petId': petId, 'fileId': fileId},
      bearerToken: await _readAccessToken('로그인 정보가 없어 참여할 수 없습니다.'),
      fallbackMessage: '사진 저장에 실패했습니다.',
    );
    if (payload is Map<String, dynamic>) {
      return PhotoParticipateResult.fromJson(payload);
    }
    throw const FormatException('잘못된 응답 형식입니다.');
  }

  Future<String> _readAccessToken(String emptyMessage) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw AuthException(emptyMessage);
    }
    return accessToken.trim();
  }
}

final photoEventRepositoryProvider = Provider<PhotoEventRepository>((ref) {
  return BackendPhotoEventRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// 사진 이벤트 상세 provider (eventMasterId 기준)
final photoEventDetailProvider = FutureProvider.autoDispose
    .family<PhotoEventDetail, String>((ref, eventMasterId) async {
  return ref.read(photoEventRepositoryProvider).getDetail(eventMasterId);
});

/// 촬영 가능한 펫 목록 provider (eventMasterId 기준)
final photoEventPetsProvider = FutureProvider.autoDispose
    .family<List<PhotoEventPet>, String>((ref, eventMasterId) async {
  return ref.read(photoEventRepositoryProvider).getPets(eventMasterId);
});

/// 촬영 내역 provider ((eventMasterId, petId) 기준)
final photoPetHistoryProvider = FutureProvider.autoDispose
    .family<PhotoHistory, ({String eventMasterId, String petId})>(
        (ref, arg) async {
  return ref
      .read(photoEventRepositoryProvider)
      .getPetHistory(arg.eventMasterId, arg.petId);
});
