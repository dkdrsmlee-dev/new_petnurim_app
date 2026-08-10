import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/membership_models.dart';
import 'pet_repository.dart';

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

  /// 토스 결제 clientKey 조회(GET /api/v1/payments/config, public).
  ///
  /// 백엔드 secretKey 와 **짝이 되는 상점 clientKey**를 내려준다. Billing Auth 는
  /// 반드시 이 키로 실행해야 백엔드가 authKey→billingKey 발급에 성공한다.
  Future<String> getTossClientKey() async {
    final payload = await _apiClient.getJson(
      '/api/v1/payments/config',
      fallbackMessage: '결제 설정을 불러오지 못했습니다.',
    );
    final toss = payload is Map ? payload['toss'] : null;
    final clientKey = toss is Map ? toss['clientKey'] : null;
    if (clientKey is String && clientKey.trim().isNotEmpty) {
      return clientKey.trim();
    }
    throw AuthException('결제 설정(clientKey)을 확인할 수 없습니다.');
  }

  /// 멤버십 상세 조회(결제 완료·관리 화면). 카드사·가입일·다음 결제일 등 포함.
  Future<MembershipDetail> getMembershipDetail(int membershipId) async {
    final payload = await _apiClient.getJson(
      '/api/v1/memberships/$membershipId',
      bearerToken: await _token('로그인 정보가 없어 멤버십 정보를 조회할 수 없습니다.'),
      fallbackMessage: '멤버십 상세를 불러오지 못했습니다.',
    );
    return MembershipDetail.fromJson(payload);
  }

  /// 재구독(해지 취소, 자동결제 복구). 기존 billingKey 재사용 —
  /// customerKey/authKey/terms 불필요, `{myPetId, membershipMasterId}`만 전송.
  Future<CreateMembershipResult> resubscribe({
    required int myPetId,
    required int membershipMasterId,
  }) async {
    final payload = await _apiClient.postJson(
      '/api/v1/memberships',
      bearerToken: await _token('로그인 정보가 없어 재구독을 진행할 수 없습니다.'),
      body: {
        'myPetId': myPetId,
        'membershipMasterId': membershipMasterId,
      },
      fallbackMessage: '재구독에 실패했습니다.',
    );
    return CreateMembershipResult.fromJson(payload);
  }

  /// 해지 화면 정보 조회(GET /memberships/{id}/cancel-info).
  /// 남은 일수·이용 종료일·해지 사유 목록(공통코드)을 받아 해지 화면을 렌더한다.
  Future<MembershipCancelInfo> getCancelInfo(int membershipId) async {
    final payload = await _apiClient.getJson(
      '/api/v1/memberships/$membershipId/cancel-info',
      bearerToken: await _token('로그인 정보가 없어 해지 정보를 조회할 수 없습니다.'),
      fallbackMessage: '해지 정보를 불러오지 못했습니다.',
    );
    return MembershipCancelInfo.fromJson(payload);
  }

  /// 멤버십 해지 신청(POST /memberships/{id}/cancel). 현재 결제 기간까지는 유지된다.
  /// cancelReasonCodes(최소 1개)·noticeAgreed(true) 필수, ETC 선택 시 cancelReasonText 필수.
  Future<MembershipCancelResult> cancelMembership(
    int membershipId, {
    required List<String> cancelReasonCodes,
    String? cancelReasonText,
    required bool noticeAgreed,
  }) async {
    final payload = await _apiClient.postJson(
      '/api/v1/memberships/$membershipId/cancel',
      bearerToken: await _token('로그인 정보가 없어 해지를 진행할 수 없습니다.'),
      body: {
        'cancelReasonCodes': cancelReasonCodes,
        if (cancelReasonText != null && cancelReasonText.trim().isNotEmpty)
          'cancelReasonText': cancelReasonText.trim(),
        'noticeAgreed': noticeAgreed,
      },
      fallbackMessage: '멤버십 해지에 실패했습니다.',
    );
    return MembershipCancelResult.fromJson(payload);
  }

  /// 멤버십 결제 내역 조회(GET /memberships/{id}/payments). 최신순 페이징.
  /// page 는 1-indexed(백엔드 규약).
  Future<MembershipPaymentPage> getMembershipPayments(
    int membershipId, {
    int page = 1,
    int size = 100,
  }) async {
    final payload = await _apiClient.getJson(
      '/api/v1/memberships/$membershipId/payments?page=$page&size=$size',
      bearerToken: await _token('로그인 정보가 없어 결제 내역을 조회할 수 없습니다.'),
      fallbackMessage: '결제 내역을 불러오지 못했습니다.',
    );
    return MembershipPaymentPage.fromJson(payload);
  }

  /// 펫 멤버십 상태 조회(마이펫 상세). 미가입/가입중/구독취소예정.
  Future<PetMembershipStatus> getPetMembership(int myPetId) async {
    final payload = await _apiClient.getJson(
      '/api/v1/users/my-pets/$myPetId/membership',
      bearerToken: await _token('로그인 정보가 없어 멤버십 상태를 조회할 수 없습니다.'),
      fallbackMessage: '멤버십 상태를 불러오지 못했습니다.',
    );
    return PetMembershipStatus.fromJson(payload);
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

/// 멤버십 상세(결제 완료·관리 화면). key = membershipId.
final membershipDetailProvider = FutureProvider.autoDispose
    .family<MembershipDetail, int>((ref, membershipId) {
  return ref.watch(membershipRepositoryProvider).getMembershipDetail(membershipId);
});

/// 회원 탈퇴 화면용: 이 회원의 **모든 활성 구독(멤버십 상세)** 집계.
/// 회원 단위 구독 조회 API가 없어, 펫 목록 → 각 펫 멤버십(가입 여부) →
/// 가입인 펫만 상세(`periodEndDt` 포함)를 모아 반환한다. (탈퇴 상단 안내 박스용)
final withdrawActiveSubscriptionsProvider =
    FutureProvider.autoDispose<List<MembershipDetail>>((ref) async {
  final petRepo = ref.watch(petRepositoryProvider);
  final memRepo = ref.watch(membershipRepositoryProvider);
  final pets = await petRepo.getMyPetsList(limit: 100);
  final result = <MembershipDetail>[];
  for (final pet in pets.items) {
    final petId = int.tryParse(pet.myPetId);
    if (petId == null) continue;
    final status = await memRepo.getPetMembership(petId);
    final membership = status.membership;
    if (membership == null) continue; // 미가입
    result.add(await memRepo.getMembershipDetail(membership.membershipId));
  }
  return result;
});

/// 멤버십 결제 내역(최신순). key = membershipId.
final membershipPaymentsProvider = FutureProvider.autoDispose
    .family<MembershipPaymentPage, int>((ref, membershipId) {
  return ref.watch(membershipRepositoryProvider).getMembershipPayments(membershipId);
});

/// 해지 화면 정보(남은 일수·이용 종료일·사유 목록). key = membershipId.
final membershipCancelInfoProvider = FutureProvider.autoDispose
    .family<MembershipCancelInfo, int>((ref, membershipId) {
  return ref.watch(membershipRepositoryProvider).getCancelInfo(membershipId);
});

/// 펫 멤버십 상태(마이펫 상세). key = myPetId(문자열, 내부에서 int 변환).
final petMembershipProvider = FutureProvider.autoDispose
    .family<PetMembershipStatus, String>((ref, myPetId) {
  final id = int.tryParse(myPetId);
  if (id == null) {
    return Future.value(const PetMembershipStatus(isMembership: false));
  }
  return ref.watch(membershipRepositoryProvider).getPetMembership(id);
});
