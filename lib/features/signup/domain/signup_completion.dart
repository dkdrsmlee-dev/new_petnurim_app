import '../../auth/domain/auth_exception.dart';

class CompleteSignupResult {
  const CompleteSignupResult({
    required this.accessToken,
    this.refreshToken,
    this.nextStep,
  });

  factory CompleteSignupResult.fromJson(Object? payload) {
    final data = payload is Map ? payload : const <String, Object?>{};
    final accessToken = _readString(data, const [
      'accessToken',
      'token',
      'jwt',
    ]);
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException('가입완료 응답에 access token이 없습니다.');
    }

    return CompleteSignupResult(
      accessToken: accessToken,
      refreshToken: _readString(data, const ['refreshToken']),
      nextStep: _readString(data, const ['nextStep']),
    );
  }

  final String accessToken;
  final String? refreshToken;
  final String? nextStep;

  static String? _readString(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num || value is bool) {
        return '$value';
      }
    }

    return null;
  }
}
