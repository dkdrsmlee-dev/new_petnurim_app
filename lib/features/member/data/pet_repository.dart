import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/pet_breed.dart';
import '../domain/qna_models.dart'; // For CursorPaginationResponse

abstract interface class PetRepository {
  Future<CursorPaginationResponse<PetBreed>> searchBreeds({
    required String petTypeCode,
    String? choseongCode,
    String? keyword,
    String? cursor,
    int? limit,
  });
}

class BackendPetRepository implements PetRepository {
  const BackendPetRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<CursorPaginationResponse<PetBreed>> searchBreeds({
    required String petTypeCode,
    String? choseongCode,
    String? keyword,
    String? cursor,
    int? limit,
  }) async {
    final queryParameters = <String, String>{
      'petTypeCode': petTypeCode,
    };
    if (choseongCode != null && choseongCode != 'ALL') {
      queryParameters['choseongCode'] = choseongCode;
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParameters['keyword'] = keyword.trim();
    }
    if (cursor != null) {
      queryParameters['cursor'] = cursor;
    }
    if (limit != null) {
      queryParameters['limit'] = limit.toString();
    }

    final uri = Uri(
      path: '/api/v1/user/pet/breeds',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final path = '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';

    final payload = await _apiClient.getJson(
      path,
      bearerToken: await _readAccessToken('로그인 정보가 없어 품종 목록을 조회할 수 없습니다.'),
      fallbackMessage: '품종 목록을 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return CursorPaginationResponse<PetBreed>.fromJson(
        payload,
        (json) => PetBreed.fromJson(json),
      );
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  Future<String> _readAccessToken(String emptyMessage) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw AuthException(emptyMessage);
    }
    return accessToken.trim();
  }
}

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return BackendPetRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
