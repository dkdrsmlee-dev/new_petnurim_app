/// 리워드 거래 구분.
enum RewardTxnType { earn, use, expire, recover, unknown }

/// 마이펫 리워드 내역 항목 (GET /api/v1/users/my-pets/{myPetId}/reward/history).
///
/// 백엔드 응답의 item이 스웨거에 무타입(object)으로만 정의돼 있어, 관리자
/// ledger(AdminRewardLedgerItemResponse) 필드명을 기준으로 **여러 후보 키를
/// 방어적으로 파싱**한다. 실제 필드명이 확정되면 후보 키만 조정하면 된다.
class PetRewardHistoryItem {
  final String title; // 제목(예: 사진 촬영 리워드)
  final String dateText; // 표시용 날짜(2026.05.10)
  final RewardTxnType type;
  final String typeLabel; // 적립/사용/소멸/복구
  final int amount; // 절대값
  final bool isPlus; // true: +(적립/복구) / false: -(사용/소멸)

  const PetRewardHistoryItem({
    required this.title,
    required this.dateText,
    required this.type,
    required this.typeLabel,
    required this.amount,
    required this.isPlus,
  });

  factory PetRewardHistoryItem.fromJson(Map<String, dynamic> json) {
    final title = _pickString(json, const [
          'detailContent',
          'rewardName',
          'eventTitle',
          'title',
          'sourceName',
          'description',
        ]) ??
        '';
    final rawDate = _pickString(json, const [
          'txnDt',
          'regDt',
          'createdAt',
          'date',
          'expireDt',
        ]) ??
        '';
    final code = (_pickString(json, const [
              'txnTypeCode',
              'typeCode',
              'rewardTxnTypeCode',
              'historyType',
            ]) ??
            '')
        .toUpperCase();
    final serverLabel = _pickString(json, const ['txnTypeName', 'typeName']);
    final rawAmt = _pickInt(json, const [
      'txnAmt',
      'amount',
      'rewardAmt',
      'amt',
      'value',
    ]);

    final type = _typeFromCode(code);
    final isPlus =
        type == RewardTxnType.earn || type == RewardTxnType.recover;

    return PetRewardHistoryItem(
      title: title,
      dateText: _formatDate(rawDate),
      type: type,
      typeLabel: serverLabel ?? _labelOf(type),
      amount: rawAmt.abs(),
      isPlus: isPlus,
    );
  }

  static RewardTxnType _typeFromCode(String code) {
    switch (code) {
      case 'EARN':
        return RewardTxnType.earn;
      case 'USE':
        return RewardTxnType.use;
      case 'EXPIRE':
        return RewardTxnType.expire;
      case 'RECOVER':
        return RewardTxnType.recover;
      default:
        return RewardTxnType.unknown;
    }
  }

  static String _labelOf(RewardTxnType t) {
    switch (t) {
      case RewardTxnType.earn:
        return '적립';
      case RewardTxnType.use:
        return '사용';
      case RewardTxnType.expire:
        return '소멸';
      case RewardTxnType.recover:
        return '복구';
      case RewardTxnType.unknown:
        return '';
    }
  }

  /// "2026-05-10 12:00:00" / "2026-05-10" → "2026.05.10"
  static String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final head = raw.length >= 10 ? raw.substring(0, 10) : raw;
    return head.replaceAll('-', '.');
  }

  static String? _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return null;
  }

  static int _pickInt(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is num) return v.toInt();
      final p = int.tryParse(v?.toString() ?? '');
      if (p != null) return p;
    }
    return 0;
  }
}
