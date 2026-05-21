import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/member_info.dart';
import '../domain/member_withdrawal.dart';

abstract interface class MemberRepository {
  Future<MemberInfo> getMemberInfo();

  Future<MemberWithdrawResult> withdraw({
    required String reasonCode,
    String? reasonText,
  });
}

class BackendMemberRepository implements MemberRepository {
  const BackendMemberRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<MemberInfo> getMemberInfo() async {
    // 백엔드 API가 응답하지 않거나 아직 준비되지 않아 Mock 데이터를 즉시 반환하도록 수정합니다.
    await Future.delayed(const Duration(milliseconds: 300));
    return const MemberInfo(
      name: '홍길동',
      email: 'email@email.co.kr',
      phoneNumber: '01012341234',
      address: '서울시 강남구 역삼동 123-45 12층 오크빌 1204호',
      birthDate: '20100307',
    );
  }

  @override
  Future<MemberWithdrawResult> withdraw({
    required String reasonCode,
    String? reasonText,
  }) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const AuthException('로그인 정보가 없어 회원탈퇴를 진행할 수 없습니다.');
    }

    final trimmedReasonText = reasonText?.trim();
    final payload = await _apiClient.postJson(
      '/api/v1/member/withdraw',
      bearerToken: accessToken,
      body: {
        'reasonCode': reasonCode,
        'withdrawalAgreeYn': 'Y',
        if (trimmedReasonText != null && trimmedReasonText.isNotEmpty)
          'reasonText': trimmedReasonText,
      },
      fallbackMessage: '회원탈퇴 처리에 실패했습니다.',
    );

    return MemberWithdrawResult.fromJson(payload);
  }
}

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return BackendMemberRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final memberInfoProvider = FutureProvider.autoDispose<MemberInfo>((ref) async {
  return ref.watch(memberRepositoryProvider).getMemberInfo();
});
