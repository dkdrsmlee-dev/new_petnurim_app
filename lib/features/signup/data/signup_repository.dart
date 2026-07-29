import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/identity_verification.dart';
import '../domain/signup_completion.dart';
import '../domain/signup_profile.dart';
import '../domain/signup_terms.dart';

abstract interface class SignupRepository {
  Future<List<ActiveTerm>> fetchActiveTerms({String target = 'SIGNUP'});

  Future<void> submitTerms({
    required String signupToken,
    required List<TermAgreement> agreements,
  });

  /// KCP 본인인증 거래 등록을 요청하고 인증창 URL 을 받아온다.
  Future<IdentityRequestResponse> requestIdentityVerification({
    required String signupToken,
    String purposeCode,
  });

  Future<void> verifyPhone({required String signupToken});

  Future<SignupProfileInit> fetchProfileInit({required String signupToken});

  Future<void> submitProfile({
    required String signupToken,
    required SignupProfileDraft profile,
  });

  Future<CompleteSignupResult> completeSignup({required String signupToken});
}

class BackendSignupRepository implements SignupRepository {
  const BackendSignupRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<List<ActiveTerm>> fetchActiveTerms({String target = 'SIGNUP'}) async {
    final payload = await _apiClient.getJson(
      _termsPath(target),
      fallbackMessage: '약관 목록을 불러오지 못했습니다.',
    );

    return _parseTermsPayload(payload);
  }

  @override
  Future<void> submitTerms({
    required String signupToken,
    required List<TermAgreement> agreements,
  }) async {
    _ensureSignupToken(signupToken, '회원가입 토큰이 없어 약관 동의를 저장할 수 없습니다.');
    await _apiClient.postJson(
      '/api/v1/auth/signup/terms',
      bearerToken: signupToken,
      body: {
        'terms': agreements.map((agreement) => agreement.toJson()).toList(),
      },
      fallbackMessage: '약관 동의 저장에 실패했습니다.',
    );
  }

  @override
  Future<IdentityRequestResponse> requestIdentityVerification({
    required String signupToken,
    String purposeCode = IdentityPurpose.signup,
  }) async {
    _ensureSignupToken(signupToken, '회원가입 토큰이 없어 본인인증을 진행할 수 없습니다.');
    final payload = await _apiClient.postJson(
      '/api/v1/identity-verification/request',
      bearerToken: signupToken,
      body: {'purposeCode': purposeCode},
      fallbackMessage: '본인인증 요청에 실패했습니다.',
    );
    if (payload is Map<String, dynamic>) {
      return IdentityRequestResponse.fromJson(payload);
    }
    throw const FormatException('잘못된 응답 형식입니다.');
  }

  @override
  Future<void> verifyPhone({required String signupToken}) async {
    _ensureSignupToken(signupToken, '회원가입 토큰이 없어 본인인증을 진행할 수 없습니다.');
    await _apiClient.postJson(
      '/api/v1/auth/signup/verify-phone',
      bearerToken: signupToken,
      body: const <String, Object?>{},
      fallbackMessage: '휴대폰 인증 처리에 실패했습니다.',
    );
  }

  @override
  Future<SignupProfileInit> fetchProfileInit({
    required String signupToken,
  }) async {
    _ensureSignupToken(signupToken, '회원가입 토큰이 없어 회원 초기 정보를 불러올 수 없습니다.');
    final payload = await _apiClient.getJson(
      '/api/v1/auth/signup/profile-init',
      bearerToken: signupToken,
      fallbackMessage: '회원 초기 정보를 불러오지 못했습니다.',
    );

    return SignupProfileInit.fromJson(payload);
  }

  @override
  Future<void> submitProfile({
    required String signupToken,
    required SignupProfileDraft profile,
  }) async {
    _ensureSignupToken(signupToken, '회원가입 토큰이 없어 회원정보를 저장할 수 없습니다.');
    await _apiClient.patchJson(
      '/api/v1/auth/signup/profile',
      bearerToken: signupToken,
      body: {
        'zipCode': profile.zipCode.trim(),
        'address1': profile.address1.trim(),
        'address2': profile.address2.trim(),
        'birthDate': _toApiBirthDate(profile.birthDate),
      },
      fallbackMessage: '회원정보 저장에 실패했습니다.',
    );
  }

  @override
  Future<CompleteSignupResult> completeSignup({
    required String signupToken,
  }) async {
    _ensureSignupToken(signupToken, '회원가입 토큰이 없어 가입 완료를 진행할 수 없습니다.');
    final payload = await _apiClient.postJson(
      '/api/v1/auth/signup/complete',
      bearerToken: signupToken,
      body: const <String, Object?>{},
      fallbackMessage: '회원가입 완료 처리에 실패했습니다.',
    );
    final result = CompleteSignupResult.fromJson(payload);
    await _tokenStorage.saveAccessToken(result.accessToken);

    return result;
  }

  String _termsPath(String target) {
    return '/api/v1/terms?target=${Uri.encodeQueryComponent(target)}';
  }

  List<ActiveTerm> _parseTermsPayload(Object? payload) {
    // 신규 API는 envelope 해제 후 약관 배열(data)을 반환한다.
    if (payload is List) {
      return _normalizeTerms(payload);
    }
    if (payload is Map) {
      return _normalizeTerms([payload]);
    }

    throw const AuthException('약관 목록 응답 형식이 올바르지 않습니다.');
  }

  List<ActiveTerm> _normalizeTerms(List<Object?> payload) {
    final terms = payload.map(ActiveTerm.fromJson).toList();
    terms.sort((left, right) => left.sortNo.compareTo(right.sortNo));
    return terms;
  }

  String _toApiBirthDate(String value) {
    final trimmed = value.trim();
    final koreanDateMatch = RegExp(
      r'^(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일$',
    ).firstMatch(trimmed);
    if (koreanDateMatch != null) {
      final year = koreanDateMatch.group(1)!;
      final month = koreanDateMatch.group(2)!.padLeft(2, '0');
      final day = koreanDateMatch.group(3)!.padLeft(2, '0');
      return '$year$month$day';
    }

    final hyphenMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch(trimmed);
    if (hyphenMatch != null) {
      final year = hyphenMatch.group(1)!;
      final month = hyphenMatch.group(2)!;
      final day = hyphenMatch.group(3)!;
      return '$year$month$day';
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      return digits;
    }

    return trimmed;
  }

  void _ensureSignupToken(String signupToken, String message) {
    if (signupToken.trim().isEmpty) {
      throw AuthException(message);
    }
  }
}
