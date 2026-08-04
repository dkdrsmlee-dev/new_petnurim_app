import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/pet_breed.dart';
import '../domain/pet_models.dart';
import '../domain/pet_reward_history.dart';
import '../domain/qna_models.dart'; // For CursorPaginationResponse

abstract interface class PetRepository {
  Future<CursorPaginationResponse<PetBreed>> searchBreeds({
    required String petTypeCode,
    String? choseongCode,
    String? keyword,
    String? cursor,
    int? limit,
  });

  Future<CreateMyPetResponse> createMyPet({
    required String petTypeCode,
    required String petName,
    int? petBreedId,
    required int petAge,
    required String familyDt,
    required String genderCode,
    required String neuteredYn,
    required double weightKg,
    required String weightMeasureDt,
    required String representYn,
    int? profileFileId,
  });

  Future<MyPetDetailResponse> getMyPetDetail(String myPetId);

  /// 마이펫 리워드 요약 조회 (총 보유/누적 적립/이번 달 적립·사용)
  Future<PetRewardSummary> getPetRewardSummary(String myPetId);

  /// 마이펫 리워드 내역 조회 (커서 무한스크롤).
  /// [historyType] ALL(이용내역=EARN/USE/RECOVER) / EXPIRE(소멸내역).
  Future<CursorPaginationResponse<PetRewardHistoryItem>> getPetRewardHistory({
    required String myPetId,
    String historyType,
    String? cursor,
    int? limit,
  });

  Future<CursorPaginationResponse<MyPetListItem>> getMyPetsList({
    String? cursor,
    int? limit,
  });

  Future<void> updateMyPet({
    required String myPetId,
    required String petTypeCode,
    required String petName,
    required int petAge,
    required String genderCode,
    required String neuteredYn,
    required double weightKg,
    required String representYn,
    int? petBreedId,
    int? profileFileId,
    String? familyDt,
    String? weightMeasureDt,
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
    if (choseongCode != null) {
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

  @override
  Future<CreateMyPetResponse> createMyPet({
    required String petTypeCode,
    required String petName,
    int? petBreedId,
    required int petAge,
    required String familyDt,
    required String genderCode,
    required String neuteredYn,
    required double weightKg,
    required String weightMeasureDt,
    required String representYn,
    int? profileFileId,
  }) async {
    final body = <String, dynamic>{
      'petTypeCode': petTypeCode,
      'petName': petName,
      'petAge': petAge,
      'genderCode': genderCode,
      'neuteredYn': neuteredYn,
      'weightKg': weightKg,
      'representYn': representYn,
    };
    if (petBreedId != null) {
      body['petBreedId'] = petBreedId;
    }
    if (familyDt.isNotEmpty) {
      body['familyDt'] = familyDt;
    }
    if (weightMeasureDt.isNotEmpty) {
      body['weightMeasureDt'] = weightMeasureDt;
    }
    if (profileFileId != null) {
      body['profileFileId'] = profileFileId;
    }

    final payload = await _apiClient.postJson(
      '/api/v1/users/my-pets',
      body: body,
      bearerToken: await _readAccessToken('로그인 정보가 없어 마이펫을 등록할 수 없습니다.'),
      fallbackMessage: '마이펫 등록에 실패했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return CreateMyPetResponse.fromJson(payload);
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<MyPetDetailResponse> getMyPetDetail(String myPetId) async {
    final payload = await _apiClient.getJson(
      '/api/v1/users/my-pets/$myPetId',
      bearerToken: await _readAccessToken('로그인 정보가 없어 마이펫 상세를 조회할 수 없습니다.'),
      fallbackMessage: '마이펫 상세 정보를 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return MyPetDetailResponse.fromJson(payload);
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<PetRewardSummary> getPetRewardSummary(String myPetId) async {
    final payload = await _apiClient.getJson(
      '/api/v1/users/my-pets/$myPetId/reward',
      bearerToken: await _readAccessToken('로그인 정보가 없어 리워드 정보를 조회할 수 없습니다.'),
      fallbackMessage: '리워드 정보를 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return PetRewardSummary.fromJson(payload);
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<CursorPaginationResponse<PetRewardHistoryItem>> getPetRewardHistory({
    required String myPetId,
    String historyType = 'ALL',
    String? cursor,
    int? limit,
  }) async {
    final queryParameters = <String, String>{'historyType': historyType};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    if (limit != null) {
      queryParameters['limit'] = limit.toString();
    }

    final uri = Uri(
      path: '/api/v1/users/my-pets/$myPetId/reward/history',
      queryParameters: queryParameters,
    );
    final path = '${uri.path}?${uri.query}';

    final payload = await _apiClient.getJson(
      path,
      bearerToken: await _readAccessToken('로그인 정보가 없어 리워드 내역을 조회할 수 없습니다.'),
      fallbackMessage: '리워드 내역을 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return CursorPaginationResponse<PetRewardHistoryItem>.fromJson(
        payload,
        (json) => PetRewardHistoryItem.fromJson(json),
      );
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<CursorPaginationResponse<MyPetListItem>> getMyPetsList({
    String? cursor,
    int? limit,
  }) async {
    final queryParameters = <String, String>{};
    if (cursor != null) {
      queryParameters['cursor'] = cursor;
    }
    if (limit != null) {
      queryParameters['limit'] = limit.toString();
    }

    final uri = Uri(
      path: '/api/v1/users/my-pets',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final path = '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';

    final payload = await _apiClient.getJson(
      path,
      bearerToken: await _readAccessToken('로그인 정보가 없어 마이펫 목록을 불러올 수 없습니다.'),
      fallbackMessage: '마이펫 목록을 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return CursorPaginationResponse<MyPetListItem>.fromJson(
        payload,
        (json) => MyPetListItem.fromJson(json),
      );
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<void> updateMyPet({
    required String myPetId,
    required String petTypeCode,
    required String petName,
    required int petAge,
    required String genderCode,
    required String neuteredYn,
    required double weightKg,
    required String representYn,
    int? petBreedId,
    int? profileFileId,
    String? familyDt,
    String? weightMeasureDt,
  }) async {
    String? formattedFamilyDt = familyDt;
    if (familyDt != null && familyDt.length >= 10) {
      formattedFamilyDt = familyDt.substring(0, 10);
    }
    String? formattedWeightMeasureDt = weightMeasureDt;
    if (weightMeasureDt != null && weightMeasureDt.length >= 10) {
      formattedWeightMeasureDt = weightMeasureDt.substring(0, 10);
    }

    final body = <String, dynamic>{
      'petTypeCode': petTypeCode,
      'petName': petName,
      'petAge': petAge,
      'genderCode': genderCode,
      'neuteredYn': neuteredYn,
      'weightKg': weightKg,
      'representYn': representYn,
    };
    if (petBreedId != null) {
      body['petBreedId'] = petBreedId;
    }
    if (profileFileId != null) {
      body['profileFileId'] = profileFileId;
    }
    if (formattedFamilyDt != null) {
      body['familyDt'] = formattedFamilyDt;
    }
    if (formattedWeightMeasureDt != null) {
      body['weightMeasureDt'] = formattedWeightMeasureDt;
    }

    await _apiClient.patchJson(
      '/api/v1/users/my-pets/$myPetId',
      body: body,
      bearerToken: await _readAccessToken('로그인 정보가 없어 마이펫 정보를 수정할 수 없습니다.'),
      fallbackMessage: '마이펫 정보를 수정하지 못했습니다.',
    );
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

/// 마이펫 리워드 요약(총 보유/이번 달 적립·사용). 상세·카드에서 공용 사용.
final petRewardSummaryProvider =
    FutureProvider.autoDispose.family<PetRewardSummary, String>((ref, myPetId) async {
  return ref.read(petRepositoryProvider).getPetRewardSummary(myPetId);
});
