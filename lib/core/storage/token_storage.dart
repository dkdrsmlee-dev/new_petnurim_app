import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readAccessToken();

  Future<void> saveAccessToken(String token);

  Future<void> clearAccessToken();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  static const _accessTokenKey = 'petnurim.accessToken';

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
  Future<void> clearAccessToken() {
    return _secureStorage.delete(key: _accessTokenKey);
  }
}

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({String? initialAccessToken})
    : _accessToken = initialAccessToken;

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
  return const SecureTokenStorage(secureStorage: FlutterSecureStorage());
});
