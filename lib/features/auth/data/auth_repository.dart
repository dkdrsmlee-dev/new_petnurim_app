import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../native/native_social_login_service.dart';
import '../domain/auth_exception.dart';
import '../domain/login_config.dart';
import '../domain/social_login_result.dart';
import '../domain/social_provider.dart';

abstract interface class AuthRepository {
  Future<LoginConfig> fetchLoginConfig();

  Future<SocialLoginResult> loginWithProvider(SocialProvider provider);

  Future<void> logout();
}

class BackendAuthRepository implements AuthRepository {
  const BackendAuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    required NativeSocialLoginService nativeSocialLoginService,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage,
       _nativeSocialLoginService = nativeSocialLoginService;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final NativeSocialLoginService _nativeSocialLoginService;

  @override
  Future<LoginConfig> fetchLoginConfig() async {
    final payload = await _apiClient.getJson(
      '/api/v1/auth/config',
      fallbackMessage: '로그인 설정을 불러오지 못했습니다.',
    );

    return LoginConfig.fromJson(payload);
  }

  @override
  Future<SocialLoginResult> loginWithProvider(SocialProvider provider) async {
    final nativeResult = await _nativeSocialLoginService.loginWithProvider(
      provider,
    );
    final backendPayload = await _apiClient.postJson(
      '/api/v1/auth/social/${provider.name}',
      body: {
        'provider': provider.backendValue,
        'providerAccessToken': nativeResult.providerAccessToken,
      },
      fallbackMessage: '${provider.label} 로그인 처리에 실패했습니다.',
    );
    final result = SocialLoginResult.fromBackend(
      provider: provider,
      payload: backendPayload,
      nativeRefreshToken: nativeResult.providerRefreshToken,
      nativeProviderUserId: nativeResult.providerUserId,
      nativeName: _fallbackName(provider, nativeResult.name),
      nativePhone: nativeResult.phone ?? '',
    );

    result.validateCredential();

    if (result.nextStep == SocialLoginNextStep.home) {
      final accessToken = result.accessToken;
      if (accessToken == null || accessToken.trim().isEmpty) {
        throw const AuthException('로그인 완료에 필요한 access token을 받지 못했습니다.');
      }
      await _tokenStorage.saveAccessToken(accessToken);

      final refreshToken = result.refreshToken;
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await _tokenStorage.saveRefreshToken(refreshToken);
      }
    }

    return result;
  }

  @override
  Future<void> logout() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }
    await _apiClient.postJson(
      '/api/v1/auth/logout',
      bearerToken: token.trim(),
      fallbackMessage: '로그아웃 처리에 실패했습니다.',
    );
  }

  String _fallbackName(SocialProvider provider, String? name) {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return trimmedName;
    }

    return '${provider.label} 사용자';
  }
}
