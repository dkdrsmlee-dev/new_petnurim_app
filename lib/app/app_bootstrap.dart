import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/onboarding_storage.dart';
import '../core/storage/token_storage.dart';
import 'app_routes.dart';

enum AppBootstrapDestination { onboarding, authStart, home }

class AppBootstrapState {
  const AppBootstrapState({
    required this.destination,
    required this.onboardingSeen,
    required this.accessToken,
  });

  final AppBootstrapDestination destination;
  final bool onboardingSeen;
  final String? accessToken;

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  String get nextRoute {
    switch (destination) {
      case AppBootstrapDestination.onboarding:
        return AppRoutes.onboarding;
      case AppBootstrapDestination.authStart:
        return AppRoutes.authStart;
      case AppBootstrapDestination.home:
        return AppRoutes.home;
    }
  }
}

class AppBootstrapService {
  const AppBootstrapService({
    required TokenStorage tokenStorage,
    required OnboardingStorage onboardingStorage,
  }) : _tokenStorage = tokenStorage,
       _onboardingStorage = onboardingStorage;

  final TokenStorage _tokenStorage;
  final OnboardingStorage _onboardingStorage;

  Future<AppBootstrapState> load() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final normalizedToken = accessToken?.trim();
    final onboardingSeen = await _onboardingStorage.readOnboardingSeen();
    final hasToken = normalizedToken != null && normalizedToken.isNotEmpty;

    if (hasToken) {
      return AppBootstrapState(
        destination: AppBootstrapDestination.home,
        onboardingSeen: onboardingSeen,
        accessToken: normalizedToken,
      );
    }

    return AppBootstrapState(
      destination: onboardingSeen
          ? AppBootstrapDestination.authStart
          : AppBootstrapDestination.onboarding,
      onboardingSeen: onboardingSeen,
      accessToken: null,
    );
  }
}

final appBootstrapServiceProvider = Provider<AppBootstrapService>((ref) {
  return AppBootstrapService(
    tokenStorage: ref.watch(tokenStorageProvider),
    onboardingStorage: ref.watch(onboardingStorageProvider),
  );
});

final appBootstrapStateProvider = FutureProvider<AppBootstrapState>((ref) {
  return ref.watch(appBootstrapServiceProvider).load();
});
