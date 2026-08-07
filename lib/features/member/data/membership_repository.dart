import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/membership_models.dart';

/// 멤버십(구독) API. Phase 1 = 가입 플로우(guide/validate/create).
/// (카드 변경/취소/재구독/상태 조회는 이후 Phase 에서 확장)
class MembershipRepository {
  const MembershipRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// 가입 가능 멤버십 상품 목록(가격·혜택).
  Future<List<MembershipGuideItem>> getGuide() async {
    final payload = await _apiClient.getJson(
      '/api/v1/memberships/guide',
      bearerToken: await _token('로그인 정보가 없어 멤버십 정보를 조회할 수 없습니다.'),
      fallbackMessage: '멤버십 가입 안내를 불러오지 못했습니다.',
    );
    final list = payload is Map ? payload['memberships'] : null;
    if (list is List) {
      return list.map(MembershipGuideItem.fromJson).toList();
    }
    return const [];
  }

  /// 가입 사전 검증(Billing Auth 실행 전). 통과 시 true.
  Future<bool> validate({
    required int myPetId,
    required int membershipMasterId,
    required List<int> termsHistoryIds,
  }) async {
    final payload = await _apiClient.postJson(
      '/api/v1/memberships/validate',
      bearerToken: await _token('로그인 정보가 없어 가입을 진행할 수 없습니다.'),
      body: {
        'myPetId': myPetId,
        'membershipMasterId': membershipMasterId,
        'termsHistoryIds': termsHistoryIds,
      },
      fallbackMessage: '멤버십 가입 검증에 실패했습니다.',
    );
    return payload is Map && payload['valid'] == true;
  }

  /// 멤버십 가입(토스 Billing). authKey/customerKey 는 Billing Auth 결과.
  Future<CreateMembershipResult> create({
    required int myPetId,
    required int membershipMasterId,
    required String customerKey,
    required String authKey,
    required List<int> termsHistoryIds,
  }) async {
    final payload = await _apiClient.postJson(
      '/api/v1/memberships',
      bearerToken: await _token('로그인 정보가 없어 가입을 진행할 수 없습니다.'),
      body: {
        'myPetId': myPetId,
        'membershipMasterId': membershipMasterId,
        'customerKey': customerKey,
        'authKey': authKey,
        'terms': termsHistoryIds
            .map((id) => {'termsHistoryId': id})
            .toList(),
      },
      fallbackMessage: '멤버십 가입에 실패했습니다.',
    );
    return CreateMembershipResult.fromJson(payload);
  }

  Future<String> _token(String emptyMessage) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw AuthException(emptyMessage);
    }
    return token.trim();
  }
}

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// 가입 가능 멤버십 상품 목록(혜택 화면에서 구독).
final membershipGuideProvider =
    FutureProvider.autoDispose<List<MembershipGuideItem>>((ref) {
  return ref.watch(membershipRepositoryProvider).getGuide();
});
