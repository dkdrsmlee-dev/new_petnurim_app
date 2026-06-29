import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/notice_models.dart';
import '../domain/qna_models.dart';

abstract interface class BoardRepository {
  Future<CursorPaginationResponse<QnaItem>> getQnaList({
    String? cursor,
    int? limit,
  });

  Future<QnaDetail> getQnaDetail(String id);

  Future<CursorPaginationResponse<NoticeItem>> getNoticeList({
    String? cursor,
    int? limit,
    String? title,
  });

  Future<NoticeDetail> getNoticeDetail(String id);

  Future<void> createQna({
    required String qnaTypeCode,
    required String title,
    required String content,
    List<String>? fileIds,
  });

  Future<void> deleteQna(String id);

  Future<void> updateQna({
    required String id,
    required String qnaTypeCode,
    required String title,
    required String content,
    List<String>? fileIds,
  });

  Future<Uint8List> downloadFile(String fileId);
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
    final fileDtos = fileIds?.map((id) {
      return {
        'fileId': id,
      };
    }).toList();

    await _apiClient.postJson(
      '/api/v1/board/qnas',
      bearerToken: await _readAccessToken('로그인 정보가 없어 1:1 문의를 등록할 수 없습니다.'),
      body: {
        'qnaTypeCode': qnaTypeCode,
        'title': title,
        'content': content,
        'files': fileDtos ?? [],
      },
      fallbackMessage: '1:1 문의 등록에 실패했습니다.',
    );
  }

  @override
  Future<void> deleteQna(String id) async {
    await _apiClient.deleteJson(
      '/api/v1/board/qnas/$id',
      bearerToken: await _readAccessToken('로그인 정보가 없어 1:1 문의를 삭제할 수 없습니다.'),
      fallbackMessage: '1:1 문의 삭제에 실패했습니다.',
    );
  }

  @override
  Future<void> updateQna({
    required String id,
    required String qnaTypeCode,
    required String title,
    required String content,
    List<String>? fileIds,
  }) async {
    final fileDtos = fileIds?.map((id) {
      return {
        'fileId': id,
      };
    }).toList();

    await _apiClient.putJson(
      '/api/v1/board/qnas/$id',
      bearerToken: await _readAccessToken('로그인 정보가 없어 1:1 문의를 수정할 수 없습니다.'),
      body: {
        'qnaTypeCode': qnaTypeCode,
        'title': title,
        'content': content,
        'files': fileDtos ?? [],
      },
      fallbackMessage: '1:1 문의 수정에 실패했습니다.',
    );
  }

  @override
  Future<Uint8List> downloadFile(String fileId) async {
    return await _apiClient.getBytes(
      '/api/v1/files/$fileId/thumb',
      bearerToken: await _readAccessToken('로그인 정보가 없어 파일을 다운로드할 수 없습니다.'),
      fallbackMessage: '파일 다운로드에 실패했습니다.',
    );
  }

  @override
  Future<CursorPaginationResponse<NoticeItem>> getNoticeList({
    String? cursor,
    int? limit,
    String? title,
  }) async {
    final queryParameters = <String, String>{};
    if (cursor != null) queryParameters['cursor'] = cursor;
    if (limit != null) queryParameters['limit'] = limit.toString();
    if (title != null) queryParameters['title'] = title;

    final uri = Uri(
      path: '/api/v1/board/notices',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final path = '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';

    final payload = await _apiClient.getJson(
      path,
      fallbackMessage: '공지사항 목록을 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return CursorPaginationResponse<NoticeItem>.fromJson(
        payload,
        (json) => NoticeItem.fromJson(json),
      );
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<NoticeDetail> getNoticeDetail(String id) async {
    final payload = await _apiClient.getJson(
      '/api/v1/board/notices/$id',
      fallbackMessage: '공지사항 상세를 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return NoticeDetail.fromJson(payload);
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
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
