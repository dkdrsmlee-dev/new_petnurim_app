import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingStorage {
  Future<bool> readOnboardingSeen();

  Future<void> saveOnboardingSeen(bool seen);
}

class SharedPreferencesOnboardingStorage implements OnboardingStorage {
  static const _onboardingSeenKey = 'petnurim.onboardingSeen';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<bool> readOnboardingSeen() async {
    final preferences = await _preferences;
    return preferences.getBool(_onboardingSeenKey) ?? false;
  }

  @override
  Future<void> saveOnboardingSeen(bool seen) async {
    final preferences = await _preferences;
    await preferences.setBool(_onboardingSeenKey, seen);
  }
}

class InMemoryOnboardingStorage implements OnboardingStorage {
  InMemoryOnboardingStorage({bool initialSeen = false})
    : _onboardingSeen = initialSeen;

  bool _onboardingSeen;

  @override
  Future<bool> readOnboardingSeen() async => _onboardingSeen;

  @override
  Future<void> saveOnboardingSeen(bool seen) async {
    _onboardingSeen = seen;
  }
}

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) {
  return SharedPreferencesOnboardingStorage();
});
