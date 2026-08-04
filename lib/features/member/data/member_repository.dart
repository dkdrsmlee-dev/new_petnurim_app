import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../../signup/domain/identity_verification.dart';
import '../domain/member_info.dart';
import '../domain/member_my_page.dart';
import '../domain/member_withdrawal.dart';

abstract interface class MemberRepository {
  Future<MemberMyPage> getMyPage();

  Future<MemberInfo> getMemberInfo();

  Future<MemberWithdrawResult> withdraw({
    required String reasonCode,
    String? reasonText,
  });

  Future<void> updateMemberAddress({
    required String zipCode,
    required String address1,
    required String address2,
  });

  /// 휴대폰 번호 변경용 본인인증(KCP) 거래 등록 요청.
  /// (로그인 access token, purposeCode=CHANGE_PHONE)
  Future<IdentityRequestResponse> requestPhoneChangeVerification();

  /// 본인인증 완료 후 requestToken 으로 휴대폰 번호 변경을 확정한다.
  Future<void> changePhone({required String requestToken});
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
  Future<MemberMyPage> getMyPage() async {
    final payload = await _apiClient.getJson(
      '/api/v1/member/mypage',
      bearerToken: await _readAccessToken('로그인 정보가 없어 마이페이지를 조회할 수 없습니다.'),
      fallbackMessage: '마이페이지 정보를 불러오지 못했습니다.',
    );

    return MemberMyPage.fromJson(payload);
  }

  @override
  Future<MemberInfo> getMemberInfo() async {
    final payload = await _apiClient.getJson(
      '/api/v1/member/me',
      bearerToken: await _readAccessToken('로그인 정보가 없어 내 정보를 조회할 수 없습니다.'),
      fallbackMessage: '내 정보를 불러오지 못했습니다.',
    );

    return MemberInfo.fromJson(payload);
  }

  @override
  Future<void> updateMemberAddress({
    required String zipCode,
    required String address1,
    required String address2,
  }) async {
    await _apiClient.patchJson(
      '/api/v1/member/address',
      bearerToken: await _readAccessToken('로그인 정보가 없어 주소를 수정할 수 없습니다.'),
      body: {
        'zipCode': zipCode,
        'address1': address1,
        'address2': address2,
      },
      fallbackMessage: '주소를 수정하지 못했습니다.',
    );
  }

  @override
  Future<IdentityRequestResponse> requestPhoneChangeVerification() async {
    final payload = await _apiClient.postJson(
      '/api/v1/identity-verification/request',
      bearerToken:
          await _readAccessToken('로그인 정보가 없어 본인인증을 진행할 수 없습니다.'),
      body: {'purposeCode': IdentityPurpose.changePhone},
      fallbackMessage: '본인인증 요청에 실패했습니다.',
    );
    if (payload is Map<String, dynamic>) {
      return IdentityRequestResponse.fromJson(payload);
    }
    throw const FormatException('잘못된 응답 형식입니다.');
  }

  @override
  Future<void> changePhone({required String requestToken}) async {
    await _apiClient.patchJson(
      '/api/v1/member/phone',
      bearerToken:
          await _readAccessToken('로그인 정보가 없어 휴대폰 번호를 변경할 수 없습니다.'),
      body: {'requestToken': requestToken},
      fallbackMessage: '휴대폰 번호 변경에 실패했습니다.',
    );
  }

  @override
  Future<MemberWithdrawResult> withdraw({
    required String reasonCode,
    String? reasonText,
  }) async {
    final trimmedReasonText = reasonText?.trim();
    final payload = await _apiClient.postJson(
      '/api/v1/member/withdraw',
      bearerToken: await _readAccessToken('로그인 정보가 없어 회원탈퇴를 진행할 수 없습니다.'),
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

  Future<String> _readAccessToken(String emptyMessage) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw AuthException(emptyMessage);
    }

    return accessToken.trim();
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

final memberMyPageProvider = FutureProvider.autoDispose<MemberMyPage>((
  ref,
) async {
  return ref.watch(memberRepositoryProvider).getMyPage();
});
