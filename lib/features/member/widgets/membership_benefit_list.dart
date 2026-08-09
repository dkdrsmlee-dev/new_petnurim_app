import 'package:flutter/material.dart';

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
  static const List<IconData> _iconGlyphs = [
    Icons.card_giftcard,
    Icons.paid,
    Icons.workspace_premium,
  ];

  static const List<MembershipBenefit> _fallback = [
    MembershipBenefit(name: '기본 리워드 적립', desc: '결제 금액의 1%'),
    MembershipBenefit(name: '결제 금액과 동일한 리워드', desc: '결제와 동시에 100% 지급'),
    MembershipBenefit(name: '기본 서비스 이용', desc: '멤버십의 모든 기본 서비스 이용'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = benefits.isNotEmpty ? benefits : _fallback;
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
    final glyph = _iconGlyphs[i % _iconGlyphs.length];
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(glyph, size: 24, color: Colors.white),
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
