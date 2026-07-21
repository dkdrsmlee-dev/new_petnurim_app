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

  final String withdrawalStatus;
  final String effectiveDt;

  static String _readString(Object? value, String fallback) =>
      JsonReader.plainString(value) ?? fallback;
}
