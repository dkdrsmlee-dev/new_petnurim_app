import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// 인증 파일 이미지(`/api/v1/files/...`)의 영구(디스크) 캐시.
///
/// 백엔드 파일은 **fileId 가 불변**이다(내용 교체 API 없음 · 변경 시 새 fileId 발급).
/// 따라서 `fileId(+variant)` 를 키로 디스크에 저장해두면 앱을 껐다 켜도
/// 네트워크 없이 즉시 로드된다. 이미지가 바뀌면 templates 가 **새 fileId** 를
/// 내려주므로 자연히 캐시 미스 → 새로 받는다(별도 무효화 불필요).
class AuthedFileDiskCache {
  AuthedFileDiskCache._();

  static Directory? _dir;

  static Future<Directory?> _cacheDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    try {
      final base = await getTemporaryDirectory();
      final dir = Directory('${base.path}/authed_file_cache');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _dir = dir;
      return dir;
    } catch (_) {
      return null;
    }
  }

  static String _fileName(String fileId, String? variant) {
    final v = (variant == null || variant.isEmpty) ? 'orig' : variant;
    final safeId = fileId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final safeV = v.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${safeId}__$safeV';
  }

  /// 디스크 캐시에서 읽는다. 없거나 실패 시 null.
  static Future<Uint8List?> read(String fileId, String? variant) async {
    try {
      final dir = await _cacheDir();
      if (dir == null) return null;
      final file = File('${dir.path}/${_fileName(fileId, variant)}');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) return bytes;
      }
    } catch (_) {
      // 읽기 실패는 무시(네트워크로 폴백).
    }
    return null;
  }

  /// 디스크 캐시에 저장한다(best-effort).
  static Future<void> write(
    String fileId,
    String? variant,
    Uint8List bytes,
  ) async {
    try {
      final dir = await _cacheDir();
      if (dir == null) return;
      final file = File('${dir.path}/${_fileName(fileId, variant)}');
      await file.writeAsBytes(bytes, flush: false);
    } catch (_) {
      // 쓰기 실패는 무시(다음 진입에 다시 시도).
    }
  }
}
