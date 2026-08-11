import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/auth_exception.dart';
import '../domain/payment_method_models.dart';

/// 회원 결제수단(카드 지갑) API. `/api/v1/payment-methods`.
class PaymentMethodRepository {
  const PaymentMethodRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// 결제수단 목록(기본 결제수단 우선, 최신 등록순).
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final payload = await _apiClient.getJson(
      '/api/v1/payment-methods',
      bearerToken: await _token('로그인 정보가 없어 결제수단을 조회할 수 없습니다.'),
      fallbackMessage: '결제수단을 불러오지 못했습니다.',
    );
    final list = payload is Map ? payload['paymentMethods'] : null;
    if (list is List) {
      return list.map(PaymentMethod.fromJson).toList();
    }
    return const [];
  }

  /// 결제수단 등록. 토스 Billing Auth 결과(authKey)와 동일 customerKey 를 전송하면
  /// 백엔드가 billingKey 를 발급해 카드를 저장한다.
  Future<void> registerPaymentMethod({
    required String authKey,
    required String customerKey,
  }) async {
    await _apiClient.postJson(
      '/api/v1/payment-methods',
      bearerToken: await _token('로그인 정보가 없어 카드를 등록할 수 없습니다.'),
      body: {'authKey': authKey, 'customerKey': customerKey},
      fallbackMessage: '카드 등록에 실패했습니다.',
    );
  }

  /// 결제수단 삭제(비활성화). 기본카드 삭제 시 백엔드가 다음 카드를 기본으로 재지정.
  Future<PaymentMethodDeleteResult> deletePaymentMethod(
    int userPaymentMethodId,
  ) async {
    final payload = await _apiClient.deleteJson(
      '/api/v1/payment-methods/$userPaymentMethodId',
      bearerToken: await _token('로그인 정보가 없어 카드를 삭제할 수 없습니다.'),
      fallbackMessage: '카드 삭제에 실패했습니다.',
    );
    return PaymentMethodDeleteResult.fromJson(payload);
  }

  /// 기본 결제수단 변경.
  Future<void> setDefaultPaymentMethod(int userPaymentMethodId) async {
    await _apiClient.patchJson(
      '/api/v1/payment-methods/$userPaymentMethodId/default',
      bearerToken: await _token('로그인 정보가 없어 기본 결제수단을 변경할 수 없습니다.'),
      fallbackMessage: '기본 결제수단 변경에 실패했습니다.',
    );
  }

  Future<String> _token(String emptyMessage) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw AuthException(emptyMessage);
    }
    return token.trim();
  }
}

final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((ref) {
  return PaymentMethodRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

/// 결제수단 목록. 마이페이지·결제수단 관리 화면에서 공유.
final paymentMethodsProvider =
    FutureProvider.autoDispose<List<PaymentMethod>>((ref) {
  return ref.watch(paymentMethodRepositoryProvider).getPaymentMethods();
});
