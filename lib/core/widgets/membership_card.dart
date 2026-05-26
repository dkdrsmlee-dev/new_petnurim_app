import 'package:flutter/material.dart';

/// 멤버십 카드 위젯 — Figma `Membership card` (node-id: 238:23691) 스펙 기반.
///
/// 상단에 등급명 + "현재 이용 중" 배지, 중단에 다음 결제일 / 월 구독료,
/// 하단에 "멤버십 혜택" 및 "결제 내역" 항목을 표시합니다.
class NurimMembershipCard extends StatelessWidget {
  const NurimMembershipCard({
    super.key,
    required this.tierName,
    required this.nextBillingDate,
    required this.monthlyFee,
    this.statusLabel = '현재 이용 중',
    this.onBenefitTapped,
    this.onPaymentHistoryTapped,
    this.width,
    this.padding = const EdgeInsets.all(0),
  });

  /// 등급명 (예: "브론즈", "실버", "골드")
  final String tierName;

  /// 다음 결제일 문자열 (예: "2026.05.12")
  final String nextBillingDate;

  /// 월 구독료 문자열 (예: "10,000원")
  final String monthlyFee;

  /// 상태 배지 라벨 (기본: "현재 이용 중")
  final String statusLabel;

  /// "멤버십 혜택" 항목 탭 콜백
  final VoidCallback? onBenefitTapped;

  /// "결제 내역" 항목 탭 콜백
  final VoidCallback? onPaymentHistoryTapped;

  final double? width;
  final EdgeInsetsGeometry padding;

  // ── 색상 상수 ──────────────────────────────────────────────────
  static const Color _strongTextColor = Color(0xFF30343C);
  static const Color _secondaryTextColor = Color(0xFF87909E);
  static const Color _primaryTextColor = Color(0xFF51565F);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _dividerColor = Color(0xFFE8EBF1);
  static const Color _iconBgColor = Color(0xFFF4F6F8);
  static const Color _badgeBgColor = Color(0xFFF2EFFF);
  static const Color _badgeTextColor = Color(0xFF7F4FFF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ① 상단: 왕관 + 등급명 + 배지
            _buildHeader(),
            const SizedBox(height: 0),
            // ② 중단: 결제 정보 박스
            _buildBillingBox(),
            // ③ 하단: 리스트 (멤버십 혜택 / 결제 내역)
            _buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // 왕관 아이콘
          const _CrownIcon(size: 24),
          const SizedBox(width: 6),
          // 등급명
          Expanded(
            child: Text(
              tierName,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.66,
                color: _strongTextColor,
              ),
            ),
          ),
          // "현재 이용 중" 배지
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _badgeBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
                letterSpacing: -0.66,
                color: _badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingBox() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _BillingRow(label: '다음 결제일', value: nextBillingDate, isFirst: true),
          _BillingRow(label: '월 구독료', value: monthlyFee, isFirst: false),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        _ListRow(
          icon: Icons.workspace_premium_outlined,
          label: '멤버십 혜택',
          showDivider: true,
          onTap: onBenefitTapped,
        ),
        _ListRow(
          icon: Icons.receipt_long_outlined,
          label: '결제 내역',
          showDivider: false,
          onTap: onPaymentHistoryTapped,
        ),
      ],
    );
  }
}

class _BillingRow extends StatelessWidget {
  const _BillingRow({
    required this.label,
    required this.value,
    required this.isFirst,
  });

  final String label;
  final String value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        isFirst ? 16 : 0,
        16,
        isFirst ? 0 : 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
                letterSpacing: -0.66,
                color: NurimMembershipCard._secondaryTextColor,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
              letterSpacing: -0.66,
              color: NurimMembershipCard._primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.icon,
    required this.label,
    required this.showDivider,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            // 원형 아이콘 배지
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: NurimMembershipCard._iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 14,
                color: NurimMembershipCard._secondaryTextColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  letterSpacing: -0.66,
                  color: NurimMembershipCard._secondaryTextColor,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: NurimMembershipCard._secondaryTextColor,
            ),
          ],
        ),
      ),
    );

    if (showDivider) {
      return Column(
        children: [
          row,
          const Divider(
            height: 1,
            thickness: 1,
            color: NurimMembershipCard._dividerColor,
          ),
        ],
      );
    }
    return row;
  }
}

/// 왕관 아이콘 (CustomPainter 구현)
class _CrownIcon extends StatelessWidget {
  const _CrownIcon({this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CrownPainter(),
    );
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF30343C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 왕관 몸체
    final body = Path()
      ..moveTo(w * 0.17, h - w * 0.12)
      ..lineTo(w * 0.83, h - w * 0.12)
      ..lineTo(w * 0.88, h * 0.46)
      ..lineTo(w * 0.73, h * 0.24)
      ..lineTo(w * 0.61, h * 0.62)
      ..lineTo(w * 0.5, h * 0.12)
      ..lineTo(w * 0.39, h * 0.62)
      ..lineTo(w * 0.27, h * 0.24)
      ..lineTo(w * 0.12, h * 0.46)
      ..close();

    // 왕관 하단 라인
    final baseLine = Path()
      ..moveTo(w * 0.17, h - w * 0.28)
      ..lineTo(w * 0.83, h - w * 0.28);

    canvas.drawPath(body, paint);
    canvas.drawPath(baseLine, paint);

    // 왕관 위 점 3개
    final dotPaint = Paint()
      ..color = const Color(0xFF30343C)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.5, h * 0.085), w * 0.06, dotPaint);
    canvas.drawCircle(Offset(w * 0.08, h * 0.27), w * 0.06, dotPaint);
    canvas.drawCircle(Offset(w * 0.92, h * 0.27), w * 0.06, dotPaint);
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => false;
}
