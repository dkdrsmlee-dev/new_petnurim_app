/// 본인인증(KCP) 요청 결과
///
/// - POST /api/v1/identity-verification/request 응답
class IdentityRequestResponse {
  /// 본인인증 요청 토큰(KCP 거래등록키). callback 의 reg_cert_key 와 동일하다.
  final String requestToken;

  /// 프론트가 WebView 에 그대로 로드할 URL.
  /// 백엔드가 KCP 인증창(certGateway.do)으로 자동제출하는 HTML 을 반환한다.
  final String webViewUrl;

  const IdentityRequestResponse({
    required this.requestToken,
    required this.webViewUrl,
  });

  factory IdentityRequestResponse.fromJson(Map<String, dynamic> json) {
    return IdentityRequestResponse(
      requestToken: json['requestToken']?.toString() ?? '',
      webViewUrl: json['webViewUrl']?.toString() ?? '',
    );
  }
}

/// 본인인증 목적 코드 (CommonCode: IDENTITY_VERIFICATION_PURPOSE)
class IdentityPurpose {
  static const String signup = 'SIGNUP'; // 회원가입
  static const String changePhone = 'CHANGE_PHONE'; // 휴대폰번호 변경
  static const String passwordReset = 'PASSWORD_RESET'; // 비밀번호 재설정
  static const String adult = 'ADULT'; // 성인 인증
  static const String accountDelete = 'ACCOUNT_DELETE'; // 회원 탈퇴
  static const String payment = 'PAYMENT'; // 결제
}
