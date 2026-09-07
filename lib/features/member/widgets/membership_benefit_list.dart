import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/membership_models.dart';

/// 멤버십 혜택 3종 리스트 카드 (구독중 혜택 화면·해지 화면 공용, Figma 547:12621/590:7766).
///
/// 텍스트는 `guide.benefits`(name/desc)에서 받고, 아이콘은 디자인 고정 매핑
/// (핑크 선물 / 초록 코인 / 파랑 메달). benefits 미로딩 시 정적 폴백을 쓴다.
class MembershipBenefitList extends StatelessWidget {
  const MembershipBenefitList({super.key, required this.benefits});

  final List<MembershipBenefit> benefits;

  static const List<Color> _iconBgs = [
    Color(0xFFFF8FE7), // pink/50
    Color(0xFF34EF9B), // green/70
    Color(0xFF5C9AF7), // blue
  ];
  /// Figma Membership info icon(534:20157)의 Basic/PR/Service 아이콘
  static const List<String> _iconAssets = [
    'assets/images/membership/ic_benefit_gift_24.svg',
    'assets/images/membership/ic_benefit_coin_24.svg',
    'assets/images/membership/ic_benefit_medal_24.svg',
  ];

  /// 피그마 Membership list(590:7766) 문구.
  ///
  /// 원래는 `GET /memberships/guide` 의 benefitName/benefitDesc 를 그대로 쓰고
  /// 이 목록은 응답이 비었을 때의 폴백이었다. 그런데 서버가 내려주는 문구가
  /// 디자인보다 훨씬 길어("결제 금액의 1%를 리워드로 적립합니다." 등) 좁은
  /// 화면에서 설명이 두 줄로 접히고 카드 안 정보 위계가 무너진다는 지적을
  /// 받아(검수 21행 ②) 디자인 문구를 우선 쓰도록 바꿨다.
  ///
  /// 서버 문구를 고치는 쪽이 정석이지만 스웨거에 멤버십 혜택을 등록·수정하는
  /// 관리 API 가 없다(Admin 멤버십관리는 조회 GET 만 있고 혜택 Request 스키마도
  /// 없다). 관리자 화면에서 손댈 수 없는 DB 고정값이라 앱에서 맞춘다.
  /// 나중에 서버 문구가 디자인대로 정리되면 [_designText] 우선 적용을 걷어내고
  /// `benefits` 를 그대로 쓰면 된다.
  static const List<MembershipBenefit> _designText = [
    MembershipBenefit(name: '기본 리워드 적립', desc: '결제 금액의 1%'),
    MembershipBenefit(name: '결제 금액과 동일한 리워드', desc: '결제와 동시에 100% 지급'),
    MembershipBenefit(name: '기본 서비스 이용', desc: '멤버십의 모든 기본 서비스 이용'),
  ];

  @override
  Widget build(BuildContext context) {
    // 항목 "개수"는 관리자 값을 따르고(혜택이 늘거나 줄 수 있다), 문구만
    // 디자인 값으로 덮어쓴다. 디자인에 없는 4번째부터는 관리자 문구를 쓴다.
    final source = benefits.isNotEmpty ? benefits : _designText;
    final items = [
      for (int i = 0; i < source.length; i++)
        i < _designText.length ? _designText[i] : source[i],
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            _row(items[i], i),
          ],
        ],
      ),
    );
  }

  Widget _row(MembershipBenefit b, int i) {
    final bg = _iconBgs[i % _iconBgs.length];
    final asset = _iconAssets[i % _iconAssets.length];
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: SvgPicture.asset(asset, width: 24, height: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: -0.66,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                b.desc,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF909AA9),
                  letterSpacing: -0.66,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
