import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/social_auth_config.dart';
import '../../../core/storage/last_login_storage.dart';
import '../../../core/storage/token_storage.dart';
import '../../../native/native_social_login_service.dart';
import '../data/auth_repository.dart';
import '../domain/login_config.dart';
import '../domain/social_login_result.dart';
import '../domain/social_provider.dart';

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

/// 마지막으로 로그인한 [SocialProvider]를 SharedPreferences에서 읽어옵니다.
/// 로그인 화면이 열릴 때마다 새로 로드합니다.
final lastLoginProviderProvider =
    FutureProvider.autoDispose<SocialProvider?>((ref) async {
  final storage = ref.watch(lastLoginStorageProvider);
  final raw = await storage.readLastLoginProvider();
  if (raw == null) return null;
  try {
    return SocialProvider.values.firstWhere((p) => p.name == raw);
  } catch (_) {
    return null;
  }
});
