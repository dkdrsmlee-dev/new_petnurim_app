import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/social_auth_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../../native/native_social_login_service.dart';
import '../data/auth_repository.dart';
import '../domain/login_config.dart';
import '../domain/social_login_result.dart';

final nativeSocialLoginServiceProvider = Provider<NativeSocialLoginService>((
  ref,
) {
  return KakaoNaverSocialLoginService(
    config: ref.watch(socialAuthConfigProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return BackendAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    nativeSocialLoginService: ref.watch(nativeSocialLoginServiceProvider),
  );
});

final loginConfigProvider = FutureProvider.autoDispose<LoginConfig>((ref) {
  return ref.watch(authRepositoryProvider).fetchLoginConfig();
});

class PendingSocialLoginResultNotifier extends Notifier<SocialLoginResult?> {
  @override
  SocialLoginResult? build() => null;

  void setResult(SocialLoginResult? result) {
    state = result;
  }
}

final pendingSocialLoginResultProvider =
    NotifierProvider<PendingSocialLoginResultNotifier, SocialLoginResult?>(
      PendingSocialLoginResultNotifier.new,
    );
