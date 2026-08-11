/// 회원 결제수단(카드) 모델. `GET /api/v1/payment-methods` 응답 항목.
class PaymentMethod {
  const PaymentMethod({
    required this.userPaymentMethodId,
    required this.paymentMethodCode,
    this.cardIssuerCode,
    this.cardIssuerName,
    this.cardMaskedNumber,
    required this.defaultYn,
    required this.statusCode,
  });

  final int userPaymentMethodId;
  final String paymentMethodCode;
  final String? cardIssuerCode; // 토스 issuerCode (예: "61")
  final String? cardIssuerName; // 예: "현대카드"
  final String? cardMaskedNumber; // 예: "1234********4205"
  final String defaultYn; // "Y"/"N"
  final String statusCode; // "ACTIVE" 등

  bool get isDefault => defaultYn.trim().toUpperCase() == 'Y';
  bool get isActive => statusCode.trim().toUpperCase() == 'ACTIVE';
  bool get isRestricted => !isActive;

  /// 마스킹 카드번호 앞 2자리("12"). 숫자가 없으면 빈 문자열.
  String get _maskedPrefix {
    final digits = (cardMaskedNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 2 ? digits.substring(0, 2) : '';
  }

  /// 표기 라벨 "현대카드(12**)" — 카드사명 + 앞 2자리 마스킹.
  String get cardLabel {
    final name = (cardIssuerName ?? '카드').trim();
    return '$name($_maskedPrefix**)';
  }

  factory PaymentMethod.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    String? s(Object? v) => v?.toString();
    return PaymentMethod(
      userPaymentMethodId: int.tryParse('${map['userPaymentMethodId']}') ?? 0,
      paymentMethodCode: s(map['paymentMethodCode']) ?? 'CARD',
      cardIssuerCode: s(map['cardIssuerCode']),
      cardIssuerName: s(map['cardIssuerName']),
      cardMaskedNumber: s(map['cardMaskedNumber']),
      defaultYn: s(map['defaultYn']) ?? 'N',
      statusCode: s(map['statusCode']) ?? 'ACTIVE',
    );
  }
}

/// `DELETE /api/v1/payment-methods/{id}` 결과.
class PaymentMethodDeleteResult {
  const PaymentMethodDeleteResult({
    required this.userPaymentMethodId,
    this.nextDefaultUserPaymentMethodId,
    this.message,
  });

  final int userPaymentMethodId;

  /// 기본 결제수단을 삭제한 경우 새로 기본으로 지정된 결제수단 ID(없으면 null).
  final int? nextDefaultUserPaymentMethodId;
  final String? message;

  factory PaymentMethodDeleteResult.fromJson(Object? json) {
    final map = json is Map ? json : const <String, Object?>{};
    final next = map['nextDefaultUserPaymentMethodId'];
    return PaymentMethodDeleteResult(
      userPaymentMethodId: int.tryParse('${map['userPaymentMethodId']}') ?? 0,
      nextDefaultUserPaymentMethodId:
          next == null ? null : int.tryParse('$next'),
      message: map['message']?.toString(),
    );
  }
}
