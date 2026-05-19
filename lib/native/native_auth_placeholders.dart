abstract interface class NativeSocialLoginService {
  Future<NativeSocialLoginResult> loginWithKakao();

  Future<NativeSocialLoginResult> loginWithNaver();
}

class NativeSocialLoginResult {
  const NativeSocialLoginResult({
    required this.provider,
    required this.providerAccessToken,
    this.providerUserId,
    this.name,
    this.phone,
  });

  final String provider;
  final String providerAccessToken;
  final String? providerUserId;
  final String? name;
  final String? phone;
}
