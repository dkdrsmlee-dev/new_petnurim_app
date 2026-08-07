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
