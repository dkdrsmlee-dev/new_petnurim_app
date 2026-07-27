import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/attendance_models.dart';

abstract interface class AttendanceRepository {
  /// 출석 이벤트 상세 조회 (eventMasterId 기준)
  Future<AttendanceCurrentResponse> getAttendance(String eventMasterId);

  /// 오늘 출석 처리 (eventMasterId 기준)
  Future<AttendanceCheckResponse> checkAttendance(String eventMasterId);
}

class BackendAttendanceRepository implements AttendanceRepository {
  const BackendAttendanceRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<AttendanceCurrentResponse> getAttendance(String eventMasterId) async {
    final payload = await _apiClient.getJson(
      '/api/v1/user/attendance/$eventMasterId',
      bearerToken: await _readAccessToken('로그인 정보가 없어 출석 정보를 조회할 수 없습니다.'),
      fallbackMessage: '출석 정보를 불러오지 못했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return AttendanceCurrentResponse.fromJson(payload);
    } else {
      throw const FormatException('잘못된 응답 형식입니다.');
    }
  }

  @override
  Future<AttendanceCheckResponse> checkAttendance(String eventMasterId) async {
    final payload = await _apiClient.postJson(
      '/api/v1/user/attendance/$eventMasterId/check',
      bearerToken: await _readAccessToken('로그인 정보가 없어 출석할 수 없습니다.'),
      fallbackMessage: '출석 처리에 실패했습니다.',
    );

    if (payload is Map<String, dynamic>) {
      return AttendanceCheckResponse.fromJson(payload);
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

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return BackendAttendanceRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// 출석 이벤트 상세 provider (eventMasterId 기준)
final attendanceProvider = FutureProvider.autoDispose
    .family<AttendanceCurrentResponse, String>((ref, eventMasterId) async {
  return ref.read(attendanceRepositoryProvider).getAttendance(eventMasterId);
});
