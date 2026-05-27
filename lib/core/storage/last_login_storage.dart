import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LastLoginStorage {
  Future<String?> readLastLoginProvider();

  Future<void> saveLastLoginProvider(String provider);
}

class SharedPreferencesLastLoginStorage implements LastLoginStorage {
  static const _lastLoginProviderKey = 'petnurim.lastLoginProvider';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<String?> readLastLoginProvider() async {
    final preferences = await _preferences;
    return preferences.getString(_lastLoginProviderKey);
  }

  @override
  Future<void> saveLastLoginProvider(String provider) async {
    final preferences = await _preferences;
    await preferences.setString(_lastLoginProviderKey, provider);
  }
}

class InMemoryLastLoginStorage implements LastLoginStorage {
  InMemoryLastLoginStorage({String? initialProvider})
    : _provider = initialProvider;

  String? _provider;

  @override
  Future<String?> readLastLoginProvider() async => _provider;

  @override
  Future<void> saveLastLoginProvider(String provider) async {
    _provider = provider;
  }
}

final lastLoginStorageProvider = Provider<LastLoginStorage>((ref) {
  return SharedPreferencesLastLoginStorage();
});
