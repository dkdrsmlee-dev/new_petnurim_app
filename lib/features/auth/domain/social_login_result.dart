import 'auth_exception.dart';
import 'social_provider.dart';

enum SocialLoginNextStep {
  signup,
  home;

  static SocialLoginNextStep fromBackend({
    required String? rawNextStep,
    required bool? isNewUser,
  }) {
    switch (rawNextStep?.trim().toLowerCase()) {
      case 'home':
      case 'main':
      case 'login':
        return SocialLoginNextStep.home;
      case 'signup':
      case 'join':
      case 'register':
        return SocialLoginNextStep.signup;
    }

    return isNewUser == true
        ? SocialLoginNextStep.signup
        : SocialLoginNextStep.home;
  }
}

class SocialLoginProfile {
  const SocialLoginProfile({
    required this.provider,
    required this.providerLabel,
    required this.name,
    required this.phone,
    this.providerUserId,
  });

  final SocialProvider provider;
  final String providerLabel;
  final String name;
  final String phone;
  final String? providerUserId;
}

class SocialLoginResult {
  const SocialLoginResult({
    required this.provider,
    required this.nextStep,
    required this.profile,
    this.accessToken,
    this.signupToken,
    this.refreshToken,
    this.sessionId,
    this.signupExpiresInSec,
  });

  factory SocialLoginResult.fromBackend({
    required SocialProvider provider,
    required Object? payload,
    required String? nativeRefreshToken,
    required String? nativeProviderUserId,
    required String nativeName,
    required String nativePhone,
  }) {
    final data = _asMap(payload);
    final profileData = data['profile'] is Map
        ? _asMap(data['profile'])
        : const <String, Object?>{};
    final isNewUser = _readBool(data, const [
      'isNewUser',
      'newUser',
      'requiresSignup',
    ]);
    final nextStep = SocialLoginNextStep.fromBackend(
      rawNextStep: _readString(data, const ['nextStep']),
      isNewUser: isNewUser,
    );
    final accessToken = _readString(data, const [
      'accessToken',
      'token',
      'jwt',
      'jwtToken',
    ]);
    final signupToken = _readString(data, const ['signupToken']);
    final providerUserId =
        _readString(profileData, const ['providerUserId']) ??
        nativeProviderUserId;

    return SocialLoginResult(
      provider: provider,
      nextStep: nextStep,
      accessToken: accessToken,
      signupToken: signupToken,
      refreshToken:
          _readString(data, const ['refreshToken']) ?? nativeRefreshToken,
      sessionId: _readString(data, const ['sessionId']),
      signupExpiresInSec: _readString(data, const ['signupExpiresInSec']),
      profile: SocialLoginProfile(
        provider: provider,
        providerLabel: provider.label,
        name:
            _readString(profileData, const ['name', 'nickname']) ?? nativeName,
        phone:
            _readString(profileData, const ['phone', 'mobile']) ?? nativePhone,
        providerUserId: providerUserId,
      ),
    );
  }

  final SocialProvider provider;
  final SocialLoginNextStep nextStep;
  final SocialLoginProfile profile;
  final String? accessToken;
  final String? signupToken;
  final String? refreshToken;
  final String? sessionId;
  final String? signupExpiresInSec;

  String? get credentialForNextStep {
    switch (nextStep) {
      case SocialLoginNextStep.home:
        return accessToken;
      case SocialLoginNextStep.signup:
        return signupToken ?? accessToken;
    }
  }

  void validateCredential() {
    final credential = credentialForNextStep;
    if (credential == null || credential.trim().isEmpty) {
      throw const AuthException('로그인 처리에 필요한 인증 토큰을 받지 못했습니다.');
    }
  }

  static Map<String, Object?> _asMap(Object? payload) {
    if (payload is Map) {
      return payload.map((key, value) => MapEntry('$key', value));
    }

    throw const AuthException('SNS 로그인 응답 형식이 올바르지 않습니다.');
  }

  static String? _readString(Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      final rawValue = payload[key];
      if (rawValue is String && rawValue.trim().isNotEmpty) {
        return rawValue.trim();
      }
      if (rawValue is num || rawValue is bool) {
        return '$rawValue';
      }
    }

    return null;
  }

  static bool? _readBool(Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      final rawValue = payload[key];
      if (rawValue is bool) {
        return rawValue;
      }
      if (rawValue is num) {
        return rawValue != 0;
      }
      if (rawValue is String) {
        final normalized = rawValue.trim().toLowerCase();
        if (const {'true', '1', 'y', 'yes'}.contains(normalized)) {
          return true;
        }
        if (const {'false', '0', 'n', 'no'}.contains(normalized)) {
          return false;
        }
      }
    }

    return null;
  }
}
