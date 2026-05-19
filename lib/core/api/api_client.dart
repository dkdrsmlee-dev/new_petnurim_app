import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

class ApiClient {
  const ApiClient({required AppConfig config}) : _config = config;

  final AppConfig _config;

  Uri uri(String path) => _config.apiUri(path);
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(config: ref.watch(appConfigProvider));
});
