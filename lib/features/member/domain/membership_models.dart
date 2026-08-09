import '../../../core/utils/json_reader.dart';

/// 멤버십 혜택 항목(GET /memberships/guide 의 benefits[]).
class MembershipBenefit {
  const MembershipBenefit({required this.name, required this.desc});

  final String name;
  final String desc;

  factory MembershipBenefit.fromJson(Object? payload) {
    final m = payload is Map ? payload : const {};
    return MembershipBenefit(
      name: JsonReader.coerceString(m['benefitName']) ?? '',
      desc: JsonReader.coerceString(m['benefitDesc']) ?? '',
    );
  }
}

/// 가입 가능 멤버십 상품(GET /memberships/guide 의 memberships[]).
/// guide 의 `membershipId` 가 가입/검증 API 의 `membershipMasterId` 이다.
class MembershipGuideItem {
  const MembershipGuideItem({
    required this.membershipMasterId,
    required this.membershipCode,
    required this.membershipName,
    required this.monthlyFee,
    required this.benefits,
  });

  final int membershipMasterId;
  final String membershipCode;
  final String membershipName;
  final int monthlyFee;
  final List<MembershipBenefit> benefits;

  factory MembershipGuideItem.fromJson(Object? payload) {
    final m = payload is Map ? payload : const {};
    final rawBenefits = m['benefits'];
    return MembershipGuideItem(
      membershipMasterId:
          JsonReader.asInt(m['membershipId'] ?? m['membershipMasterId']),
      membershipCode: JsonReader.coerceString(m['membershipCode']) ?? '',
      membershipName: JsonReader.coerceString(m['membershipName']) ?? '',
      monthlyFee: JsonReader.asInt(m['monthlyFee']),
      benefits: rawBenefits is List
          ? rawBenefits.map(MembershipBenefit.fromJson).toList()
          : const [],
    );
  }
}

/// 펫 멤버십 상태(GET /users/my-pets/{myPetId}/membership 의 membership).
/// statusCode: ACTIVE(가입중) / CANCEL_REQUEST(구독취소 예정, autoRenewYn=N).
class MembershipInfo {
  const MembershipInfo({
    required this.membershipId,
    required this.membershipName,
    required this.statusCode,
    required this.monthlyFee,
    required this.nextBillingDt,
    required this.autoRenewYn,
  });

  final int membershipId;
  final String membershipName;
  final String statusCode;
  final int monthlyFee;
  final String nextBillingDt; // yyyy-MM-dd
  final String autoRenewYn; // Y / N

  /// 구독취소 예정(자동결제 해지, 현재 기간까지 유지) 여부.
  bool get isCancelScheduled =>
      statusCode.trim().toUpperCase() == 'CANCEL_REQUEST' ||
      autoRenewYn.trim().toUpperCase() == 'N';

  factory MembershipInfo.fromJson(Object? payload) {
    final m = payload is Map ? payload : const {};
    return MembershipInfo(
      membershipId: JsonReader.asInt(m['membershipId']),
      membershipName: JsonReader.coerceString(m['membershipName']) ?? '',
      statusCode: JsonReader.coerceString(m['statusCode']) ?? '',
      monthlyFee: JsonReader.asInt(m['monthlyFee']),
      nextBillingDt: JsonReader.coerceString(m['nextBillingDt']) ?? '',
      autoRenewYn: JsonReader.coerceString(m['autoRenewYn']) ?? '',
    );
  }
}

/// 펫 멤버십 조회 응답 래퍼(isMembership + membership).
class PetMembershipStatus {
  const PetMembershipStatus({required this.isMembership, this.membership});

  final bool isMembership;
  final MembershipInfo? membership;

  factory PetMembershipStatus.fromJson(Object? payload) {
    final m = payload is Map ? payload : const {};
    final mem = m['membership'];
    return PetMembershipStatus(
      isMembership: m['isMembership'] == true && mem is Map,
      membership: mem is Map ? MembershipInfo.fromJson(mem) : null,
    );
  }
}

/// 멤버십 상세(GET /memberships/{membershipId}). 결제 완료·관리 화면에서 사용.
class MembershipDetail {
  const MembershipDetail({
    required this.membershipId,
    required this.membershipMasterId,
    required this.membershipName,
    required this.statusCode,
    required this.paymentAmount,
    required this.paymentCycle,
    required this.joinDt,
    required this.periodStartDt,
    required this.periodEndDt,
    required this.nextBillingDt,
    required this.autoRenewYn,
    required this.cardIssuerName,
    required this.cardMaskedNumber,
  });

  final int membershipId;
  final int membershipMasterId;
  final String membershipName;
  final String statusCode; // ACTIVE / CANCEL_REQUEST …
  final int paymentAmount;
  final String paymentCycle; // MONTH
  final String joinDt; // yyyy-MM-dd HH:mm:ss
  final String periodStartDt; // yyyy-MM-dd
  final String periodEndDt; // yyyy-MM-dd
  final String nextBillingDt; // yyyy-MM-dd
  final String autoRenewYn; // Y / N
  final String cardIssuerName; // 국민카드
  final String cardMaskedNumber; // 1234********4205

  /// 구독취소 예정(자동결제 해지, 현재 기간까지 유지) 여부.
  bool get isCancelScheduled =>
      statusCode.trim().toUpperCase() == 'CANCEL_REQUEST' ||
      autoRenewYn.trim().toUpperCase() == 'N';

  /// 결제 주기 표기(MONTH → "월 정기 결제").
  String get paymentCycleLabel {
    switch (paymentCycle.trim().toUpperCase()) {
      case 'MONTH':
        return '월 정기 결제';
      default:
        return paymentCycle.trim().isEmpty ? '월 정기 결제' : paymentCycle.trim();
    }
  }

  /// 결제 수단 표기 "국민카드(12**)" — 카드사명 + 마스킹 카드번호 앞 2자리.
  String get cardLabel {
    final issuer = cardIssuerName.trim();
    final masked = cardMaskedNumber.trim();
    if (issuer.isEmpty && masked.isEmpty) return '-';
    if (issuer.isEmpty) return masked;
    final prefix = masked.length >= 2 ? masked.substring(0, 2) : masked;
    return prefix.isEmpty ? issuer : '$issuer($prefix**)';
  }

  /// 가입 시작일시 "2026.05.30 10:45:55".
  String get joinDtDisplay => _dotDate(joinDt);

  /// 자동 갱신일(다음 결제 예정일) "2026.05.30".
  String get nextBillingDtDisplay =>
      _dotDate(nextBillingDt.length >= 10 ? nextBillingDt.substring(0, 10) : nextBillingDt);

  factory MembershipDetail.fromJson(Object? payload) {
    final m = payload is Map ? payload : const {};
    return MembershipDetail(
      membershipId: JsonReader.asInt(m['membershipId']),
      membershipMasterId: JsonReader.asInt(m['membershipMasterId']),
      membershipName: JsonReader.coerceString(m['membershipName']) ?? '',
      statusCode: JsonReader.coerceString(m['statusCode']) ?? '',
      paymentAmount: JsonReader.asInt(m['paymentAmount']),
      paymentCycle: JsonReader.coerceString(m['paymentCycle']) ?? '',
      joinDt: JsonReader.coerceString(m['joinDt']) ?? '',
      periodStartDt: JsonReader.coerceString(m['periodStartDt']) ?? '',
      periodEndDt: JsonReader.coerceString(m['periodEndDt']) ?? '',
      nextBillingDt: JsonReader.coerceString(m['nextBillingDt']) ?? '',
      autoRenewYn: JsonReader.coerceString(m['autoRenewYn']) ?? '',
      cardIssuerName: JsonReader.coerceString(m['cardIssuerName']) ?? '',
      cardMaskedNumber: JsonReader.coerceString(m['cardMaskedNumber']) ?? '',
    );
  }
}

/// yyyy-MM-dd[ HH:mm:ss] → yyyy.MM.dd[ HH:mm:ss] 표기 변환.
String _dotDate(String s) => s.trim().replaceAll('T', ' ').replaceAll('-', '.');

/// 해지 사유 항목(공통코드 CANCEL_REASON_CODE). cancel-info 의 cancelReasons[].
class CancelReasonItem {
  const CancelReasonItem({required this.code, required this.name});

  final String code;
  final String name;

  bool get isEtc => code.trim().toUpperCase() == 'ETC';

  factory CancelReasonItem.fromJson(Object? payload) {
    final m = payload is Map ? payload : const {};
    return CancelReasonItem(
      code: JsonReader.coerceString(m['code']) ?? '',
      name: JsonReader.coerceString(m['name']) ?? '',
    );
  }
}

/// 멤버십 해지 화면 정보(GET /memberships/{id}/cancel-info).
class MembershipCancelInfo {
  const MembershipCancelInfo({
    required this.membershipId,
    required this.membershipName,
    required this.statusCode,
    required this.autoRenewYn,
    required this.benefitEndDate,
    required this.benefitRemainingDays,
    required this.cancelReasons,
  });

  final int membershipId;
  final String membershipName;
  final String statusCode;
  final String autoRenewYn;
  final String benefitEndDate; // yyyy-MM-dd
  final int benefitRemainingDays;
  final List<CancelReasonItem> cancelReasons;

  factory MembershipCancelInfo.fromJson(Object? payload) {
    final m = payload is Map ? payload : const {};
    final raw = m['cancelReasons'];
    return MembershipCancelInfo(
      membershipId: JsonReader.asInt(m['membershipId']),
      membershipName: JsonReader.coerceString(m['membershipName']) ?? '',
      statusCode: JsonReader.coerceString(m['statusCode']) ?? '',
      autoRenewYn: JsonReader.coerceString(m['autoRenewYn']) ?? '',
      benefitEndDate: JsonReader.coerceString(m['benefitEndDate']) ?? '',
      benefitRemainingDays: JsonReader.asInt(m['benefitRemainingDays']),
      cancelReasons: raw is List
          ? raw.map(CancelReasonItem.fromJson).toList()
          : const [],
    );
  }
}

/// 멤버십 해지 신청 결과(POST /memberships/{id}/cancel).
class MembershipCancelResult {
  const MembershipCancelResult({
    required this.membershipId,
    required this.statusCode,
    required this.autoRenewYn,
    required this.cancelRequestDate,
    required this.benefitEndDate,
    required this.message,
  });

  final int membershipId;
  final String statusCode; // CANCEL_REQUEST
  final String autoRenewYn; // N
  final String cancelRequestDate; // yyyy-MM-dd (해지 신청일)
  final String benefitEndDate; // yyyy-MM-dd (이용 종료일)
  final String message;

  factory MembershipCancelResult.fromJson(Object? payload) {
    final m = payload is Map ? payload : const {};
    return MembershipCancelResult(
      membershipId: JsonReader.asInt(m['membershipId']),
      statusCode: JsonReader.coerceString(m['statusCode']) ?? '',
      autoRenewYn: JsonReader.coerceString(m['autoRenewYn']) ?? '',
      cancelRequestDate: JsonReader.coerceString(m['cancelRequestDate']) ?? '',
      benefitEndDate: JsonReader.coerceString(m['benefitEndDate']) ?? '',
      message: JsonReader.coerceString(m['message']) ?? '',
    );
  }
}

/// 멤버십 가입 결과(POST /memberships).
class CreateMembershipResult {
  const CreateMembershipResult({
    required this.membershipId,
    required this.statusCode,
    required this.paymentAmount,
    required this.nextBillingDt,
    required this.rewardGranted,
    required this.rewardAmount,
  });

  final int membershipId;
  final String statusCode;
  final int paymentAmount;
  final String nextBillingDt;
  final bool rewardGranted;
  final int rewardAmount;

  factory CreateMembershipResult.fromJson(Object? payload) {
    final m = payload is Map ? payload : const {};
    return CreateMembershipResult(
      membershipId: JsonReader.asInt(m['membershipId']),
      statusCode: JsonReader.coerceString(m['statusCode']) ?? '',
      paymentAmount: JsonReader.asInt(m['paymentAmount']),
      nextBillingDt: JsonReader.coerceString(m['nextBillingDt']) ?? '',
      rewardGranted: m['rewardGranted'] == true,
      rewardAmount: JsonReader.asInt(m['rewardAmount']),
    );
  }
}
