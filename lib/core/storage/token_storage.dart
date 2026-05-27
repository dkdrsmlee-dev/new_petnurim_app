import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<void> saveAccessToken(String token);
  
  Future<String?> readRefreshToken();
  Future<void> saveRefreshToken(String token);

  Future<void> clearTokens();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  static const _accessTokenKey = 'petnurim.accessToken';
  static const _refreshTokenKey = 'petnurim.refreshToken';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> readAccessToken() {
    return _secureStorage.read(key: _accessTokenKey);
  }

  @override
  Future<void> saveAccessToken(String token) {
    return _secureStorage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<String?> readRefreshToken() {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> saveRefreshToken(String token) {
    return _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  @override
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({
    String? initialAccessToken,
    String? initialRefreshToken,
  })  : _accessToken = initialAccessToken,
        _refreshToken = initialRefreshToken;

  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
  }

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return const SecureTokenStorage(secureStorage: FlutterSecureStorage());
});
