import '../../../core/utils/json_reader.dart';

class MemberWithdrawResult {
  const MemberWithdrawResult({
    required this.withdrawalStatus,
    required this.effectiveDt,
  });

  factory MemberWithdrawResult.fromJson(Object? json) {
    if (json is! Map) {
      return const MemberWithdrawResult(
        withdrawalStatus: 'COMPLETED',
        effectiveDt: '',
      );
    }

    return MemberWithdrawResult(
      withdrawalStatus: _readString(json['withdrawalStatus'], 'COMPLETED'),
      effectiveDt: _readString(json['effectiveDt'], ''),
    );
  }

  final String withdrawalStatus; // COMPLETED / PENDING
  final String effectiveDt; // 탈퇴 효력일시(yyyy-MM-dd HH:mm:ss)

  /// 구독 기간이 남아 즉시 탈퇴되지 않고 보류된 상태(효력일 = effectiveDt).
  bool get isPending => withdrawalStatus.trim().toUpperCase() == 'PENDING';

  static String _readString(Object? value, String fallback) =>
      JsonReader.plainString(value) ?? fallback;
}
