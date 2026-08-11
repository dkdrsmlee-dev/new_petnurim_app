import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 카드사 아이콘. 백엔드 `cardIssuerName`(예: "현대카드")을 Figma 로고 에셋에
/// 매핑하고, 매핑되지 않은 카드사는 일반 원형 폴백(신용카드 아이콘)으로 표시한다.
class CardIssuerIcon extends StatelessWidget {
  const CardIssuerIcon({
    super.key,
    required this.issuerName,
    this.size = 24,
    this.disabled = false,
  });

  final String? issuerName;
  final double size;

  /// 사용제한 등 비활성 상태 — 로고를 흐리게(opacity 0.3) 표시.
  final bool disabled;

  /// 카드사명 부분문자열 → 에셋 파일명. 미매핑은 폴백.
  static const Map<String, String> _assetByKeyword = {
    '국민': 'kb',
    'KB': 'kb',
    '롯데': 'lotte',
    '현대': 'hyundai',
    '하나': 'hana',
    '신한': 'shinhan',
  };

  String? get _assetPath {
    final name = issuerName ?? '';
    for (final entry in _assetByKeyword.entries) {
      if (name.contains(entry.key)) {
        return 'assets/images/card_issuers/${entry.value}.png';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final asset = _assetPath;
    final Widget icon = asset != null
        ? ClipOval(
            child: Image.asset(
              asset,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            ),
          )
        : _fallback();
    return disabled ? Opacity(opacity: 0.3, child: icon) : icon;
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgGray,
      ),
      child: Icon(
        Icons.credit_card,
        size: size * 0.58,
        color: AppColors.textMuted,
      ),
    );
  }
}
