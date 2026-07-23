import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/token_storage.dart';
import 'app_routes.dart';

enum AppBootstrapDestination { authStart, home }

class AppBootstrapState {
  const AppBootstrapState({
    required this.destination,
    required this.accessToken,
  });

  final AppBootstrapDestination destination;
  final String? accessToken;

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  String get nextRoute {
    switch (destination) {
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
  }) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  Future<AppBootstrapState> load() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final normalizedToken = accessToken?.trim();
    final hasToken = normalizedToken != null && normalizedToken.isNotEmpty;

    return AppBootstrapState(
      destination: hasToken
          ? AppBootstrapDestination.home
          : AppBootstrapDestination.authStart,
      accessToken: hasToken ? normalizedToken : null,
    );
  }
}

final appBootstrapServiceProvider = Provider<AppBootstrapService>((ref) {
  return AppBootstrapService(
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final appBootstrapStateProvider = FutureProvider<AppBootstrapState>((ref) {
  return ref.watch(appBootstrapServiceProvider).load();
});

final accessTokenProvider = Provider<String?>((ref) {
  final state = ref.watch(appBootstrapStateProvider);
  return state.value?.accessToken;
});
