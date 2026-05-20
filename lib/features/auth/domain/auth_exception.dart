class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SocialLoginCancelledException extends AuthException {
  const SocialLoginCancelledException(super.message);
}
