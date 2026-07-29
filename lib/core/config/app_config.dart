import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    this.apiBaseUrl = const String.fromEnvironment(
      'NURIM_API_BASE_URL',
      defaultValue: 'https://api-dev.petnurim.kr',
    ),
  });

  final String apiBaseUrl;

  Uri apiUri(String path) {
    final normalizedBaseUrl = apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$normalizedBaseUrl$normalizedPath');
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => const AppConfig());
