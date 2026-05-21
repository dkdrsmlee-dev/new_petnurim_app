import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/member_withdrawal.dart';

abstract interface class MemberRepository {
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
