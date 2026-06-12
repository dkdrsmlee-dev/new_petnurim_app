import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';

abstract interface class FileRepository {
  Future<Map<String, dynamic>> uploadFile({
    required List<int> fileBytes,
    required String filename,
  });

  Future<void> deleteFile(String fileId);
}

class BackendFileRepository implements FileRepository {
  const BackendFileRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<Map<String, dynamic>> uploadFile({
    required List<int> fileBytes,
    required String filename,
  }) async {
    final payload = await _apiClient.uploadFile(
      '/api/v1/files',
      fileBytes: fileBytes,
      filename: filename,
      fieldName: 'file',
      bearerToken: await _readAccessToken('로그인 정보가 없어 파일을 업로드할 수 없습니다.'),
      fallbackMessage: '파일 업로드에 실패했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return payload;
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<void> deleteFile(String fileId) async {
    await _apiClient.deleteJson(
      '/api/v1/files/$fileId',
      bearerToken: await _readAccessToken('로그인 정보가 없어 파일을 삭제할 수 없습니다.'),
      fallbackMessage: '파일 삭제에 실패했습니다.',
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

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return BackendFileRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
