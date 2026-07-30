import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../cache/authed_file_disk_cache.dart';
import '../storage/token_storage.dart';

/// 인증이 필요한 백엔드 파일(`/api/v1/files/{id}/download`)을 로드하는 ImageProvider.
///
/// [ApiClient.getBytes] 를 사용하므로 액세스 토큰 만료 시 자동으로
/// 토큰을 갱신(401 → refresh → 재시도)한 뒤 이미지를 받아온다. 또한
/// Flutter 전역 ImageCache 에 `fileId` 기준으로 정상 편입되어(== / hashCode)
/// 리빌드마다 재다운로드되지 않는다.
@immutable
class AuthedFileImage extends ImageProvider<AuthedFileImage> {
  const AuthedFileImage(
    this.fileId, {
    required this.apiClient,
    required this.tokenStorage,
    this.scale = 1.0,
    this.variant,
    this.downloadFallback = false,
  });

  final String fileId;
  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  final double scale;

  /// 파일 variant (`original`/`medium`/`thumb`). null이면 원본 다운로드.
  /// 표시 크기에 맞는 축소본을 쓰면 다운로드 시간이 단축된다.
  final String? variant;

  /// variant 로드가 실패할 때(예: 서버에 해당 variant 가 생성돼 있지 않아 404)
  /// 원본 다운로드(`/download`)로 폴백할지 여부.
  final bool downloadFallback;

  String get _path => (variant == null || variant!.isEmpty)
      ? '/api/v1/files/$fileId/download'
      : '/api/v1/files/$fileId/variant/$variant';

  String get _downloadPath => '/api/v1/files/$fileId/download';

  @override
  Future<AuthedFileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AuthedFileImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AuthedFileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key._path,
    );
  }

  Future<ui.Codec> _loadAsync(
    AuthedFileImage key,
    ImageDecoderCallback decode,
  ) async {
    // 0) 디스크 캐시 우선(fileId 불변 → 재실행에도 네트워크 없이 즉시 로드)
    final cached = await AuthedFileDiskCache.read(key.fileId, key.variant);
    if (cached != null) {
      final buffer = await ui.ImmutableBuffer.fromUint8List(cached);
      return decode(buffer);
    }

    final token = await tokenStorage.readAccessToken();

    Future<Uint8List> fetch(String path) async {
      final result = await apiClient.getBytes(path, bearerToken: token);
      if (result.isEmpty) {
        throw StateError('AuthedFileImage($fileId): 빈 이미지 응답 ($path)');
      }
      return result;
    }

    Uint8List bytes;
    try {
      bytes = await fetch(key._path);
    } catch (error) {
      // variant 로드 실패 시 원본 다운로드로 폴백(허용된 경우에만).
      final canFallback = key.downloadFallback &&
          key.variant != null &&
          key.variant!.isNotEmpty;
      if (!canFallback) rethrow;
      debugPrint('[AuthedFileImage] variant 실패 → 다운로드 폴백: ${key._downloadPath}');
      bytes = await fetch(key._downloadPath);
    }

    // 디스크 캐시에 저장(비동기, best-effort).
    unawaited(AuthedFileDiskCache.write(key.fileId, key.variant, bytes));

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthedFileImage &&
        other.fileId == fileId &&
        other.variant == variant &&
        other.downloadFallback == downloadFallback &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(fileId, variant, downloadFallback, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'AuthedFileImage')}("$fileId", scale: $scale)';
}

/// 화면 코드에서 간결하게 사용하기 위한 헬퍼.
/// `AuthedFileImage.of(ref, fileId)` 형태로 ImageProvider 를 생성한다.
extension AuthedFileImageX on AuthedFileImage {
  static AuthedFileImage of(
    WidgetRef ref,
    String fileId, {
    String? variant,
    bool downloadFallback = false,
  }) {
    return AuthedFileImage(
      fileId,
      apiClient: ref.read(apiClientProvider),
      tokenStorage: ref.read(tokenStorageProvider),
      variant: variant,
      downloadFallback: downloadFallback,
    );
  }
}
