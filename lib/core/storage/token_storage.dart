import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class TokenStorage {
  Future<String?> readAccessToken();

  Future<void> saveAccessToken(String token);

  Future<void> clearAccessToken();
}

class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
  }

  @override
  Future<void> clearAccessToken() async {
    _accessToken = null;
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return InMemoryTokenStorage();
});
