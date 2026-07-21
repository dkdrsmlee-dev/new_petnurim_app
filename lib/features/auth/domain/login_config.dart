import '../../../core/utils/json_reader.dart';
import 'auth_exception.dart';
import 'social_provider.dart';

class LoginConfig {
  const LoginConfig({
    required this.idLogin,
    required this.snsLogin,
    required this.providers,
  });

  const LoginConfig.allEnabled()
    : idLogin = false,
      snsLogin = true,
      providers = const {
        SocialProvider.kakao: true,
        SocialProvider.naver: true,
      };

  final bool idLogin;
  final bool snsLogin;
  final Map<SocialProvider, bool> providers;

  bool isProviderEnabled(SocialProvider provider) {
    return snsLogin && (providers[provider] ?? false);
  }

  factory LoginConfig.fromJson(Object? payload) {
    final data = _asMap(payload, '로그인 설정 응답 형식이 올바르지 않습니다.');
    final rawProviders = data['providers'];
    final providerMap = rawProviders is Map ? rawProviders : const {};

    return LoginConfig(
      idLogin: _readBool(data['idLogin']),
      snsLogin: _readBool(data['snsLogin']),
      providers: {
        for (final provider in SocialProvider.values)
          provider: _readProviderEnabled(providerMap, provider),
      },
    );
  }

  static bool _readProviderEnabled(
    Map<dynamic, dynamic> data,
    SocialProvider provider,
  ) {
    return _readBool(data[provider.name] ?? data[provider.backendValue]);
  }

  static Map<String, Object?> _asMap(Object? payload, String message) {
    if (payload is Map) {
      return payload.map((key, value) => MapEntry('$key', value));
    }

    throw AuthException(message);
  }

  static bool _readBool(Object? value) => JsonReader.coerceBool(value) ?? false;
}
