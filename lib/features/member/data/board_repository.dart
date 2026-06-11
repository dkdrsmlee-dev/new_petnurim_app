import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/qna_models.dart';

abstract interface class BoardRepository {
  Future<CursorPaginationResponse<QnaItem>> getQnaList({
    String? cursor,
    int? limit,
  });

  Future<QnaDetail> getQnaDetail(String id);

  Future<void> createQna({
    required String qnaTypeCode,
    required String title,
    required String content,
    List<String>? fileIds,
  });
}

class BackendBoardRepository implements BoardRepository {
  const BackendBoardRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<CursorPaginationResponse<QnaItem>> getQnaList({
    String? cursor,
    int? limit,
  }) async {
    final queryParameters = <String, String>{};
    if (cursor != null) queryParameters['cursor'] = cursor;
    if (limit != null) queryParameters['limit'] = limit.toString();

    final uri = Uri(
      path: '/api/v1/board/qnas',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    // uri.toString() includes path and query, but ApiClient.getJson expects path relative to baseUrl.
    // Wait, ApiClient._requestJson does: uri = uri(path). uri(path) is _config.apiUri(path).
    // Let's check apiUri implementation in app_config.dart to see how path is handled if it contains query parameters.
    // Normally, passing path with query parameters like "/api/v1/board/qnas?cursor=..." to apiUri works if it uses Uri.parse.
    // Let's pass a path string with query parameters to getJson.
    final path = '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';

    final payload = await _apiClient.getJson(
      path,
      bearerToken: await _readAccessToken('로그인 정보가 없어 1:1 문의 목록을 조회할 수 없습니다.'),
      fallbackMessage: '1:1 문의 목록을 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return CursorPaginationResponse<QnaItem>.fromJson(
        payload,
        (json) => QnaItem.fromJson(json),
      );
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<QnaDetail> getQnaDetail(String id) async {
    final payload = await _apiClient.getJson(
      '/api/v1/board/qnas/$id',
      bearerToken: await _readAccessToken('로그인 정보가 없어 1:1 문의 상세를 조회할 수 없습니다.'),
      fallbackMessage: '1:1 문의 상세를 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return QnaDetail.fromJson(payload);
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<void> createQna({
    required String qnaTypeCode,
    required String title,
    required String content,
    List<String>? fileIds,
  }) async {
    final fileDtos = fileIds?.map((id) => {'fileId': id}).toList();

    await _apiClient.postJson(
      '/api/v1/board/qnas',
      bearerToken: await _readAccessToken('로그인 정보가 없어 1:1 문의를 등록할 수 없습니다.'),
      body: {
        'qnaTypeCode': qnaTypeCode,
        'title': title,
        'content': content,
        if (fileDtos != null && fileDtos.isNotEmpty) 'files': fileDtos,
      },
      fallbackMessage: '1:1 문의 등록에 실패했습니다.',
    );
  }

  Future<String> _readAccessToken(String emptyMessage) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw AuthException(emptyMessage);
    }
    return accessToken.trim();
  }
}

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return BackendBoardRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
