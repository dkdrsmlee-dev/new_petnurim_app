import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/common_code.dart';

/// 백엔드 공통코드(common-codes) 조회 repository.
abstract interface class CommonCodeRepository {
  /// 단일 그룹키의 공통코드 목록을 조회한다.
  Future<List<CommonCode>> getCodes(String groupKey);
}

class BackendCommonCodeRepository implements CommonCodeRepository {
  const BackendCommonCodeRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<List<CommonCode>> getCodes(String groupKey) async {
    final token = await _tokenStorage.readAccessToken();
    final bearer =
        (token != null && token.trim().isNotEmpty) ? token.trim() : null;

    final payload = await _apiClient.getJson(
      '/api/v1/common-codes/${Uri.encodeComponent(groupKey)}',
      bearerToken: bearer,
      fallbackMessage: '공통코드를 불러오지 못했습니다.',
    );

    return _parse(payload, groupKey);
  }

  /// 응답이 List 이거나 {groupKey: [...]} 형태일 수 있어 방어적으로 파싱한다.
  List<CommonCode> _parse(Object? payload, String groupKey) {
    List<Object?> rawList = const [];
    if (payload is List) {
      rawList = payload;
    } else if (payload is Map) {
      final byGroup = payload[groupKey];
      if (byGroup is List) {
        rawList = byGroup;
      } else {
        for (final value in payload.values) {
          if (value is List) {
            rawList = value;
            break;
          }
        }
      }
    }

    final codes = rawList
        .whereType<Map>()
        .map((e) => CommonCode.fromJson(e.cast<String, dynamic>()))
        .where((code) => code.codeVal.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortNo.compareTo(b.sortNo));
    return codes;
  }
}

final commonCodeRepositoryProvider = Provider<CommonCodeRepository>((ref) {
  return BackendCommonCodeRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// 회원 탈퇴 사유 공통코드 (WITHDRAW_REASON_TYPE)
final withdrawReasonsProvider =
    FutureProvider.autoDispose<List<CommonCode>>((ref) async {
  return ref.read(commonCodeRepositoryProvider).getCodes('WITHDRAW_REASON_TYPE');
});
