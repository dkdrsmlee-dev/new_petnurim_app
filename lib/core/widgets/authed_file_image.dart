import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
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
  });

  final String fileId;
  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  final double scale;

  /// 파일 variant (`original`/`medium`/`thumb`). null이면 원본 다운로드.
  /// 표시 크기에 맞는 축소본을 쓰면 다운로드 시간이 단축된다.
  final String? variant;

  String get _path => (variant == null || variant!.isEmpty)
      ? '/api/v1/files/$fileId/download'
      : '/api/v1/files/$fileId/variant/$variant';

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
    final token = await tokenStorage.readAccessToken();
    final bytes = await apiClient.getBytes(key._path, bearerToken: token);
    if (bytes.isEmpty) {
      throw StateError('AuthedFileImage($fileId): 빈 이미지 응답');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthedFileImage &&
        other.fileId == fileId &&
        other.variant == variant &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(fileId, variant, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'AuthedFileImage')}("$fileId", scale: $scale)';
}

/// 화면 코드에서 간결하게 사용하기 위한 헬퍼.
/// `AuthedFileImage.of(ref, fileId)` 형태로 ImageProvider 를 생성한다.
extension AuthedFileImageX on AuthedFileImage {
  static AuthedFileImage of(WidgetRef ref, String fileId, {String? variant}) {
    return AuthedFileImage(
      fileId,
      apiClient: ref.read(apiClientProvider),
      tokenStorage: ref.read(tokenStorageProvider),
      variant: variant,
    );
  }
}
