import 'package:flutter/painting.dart';

/// 앱 전역 색상 디자인 토큰.
///
/// 프로젝트 전반에 하드코딩되어 있던 `Color(0xFF...)` 리터럴 및 각 화면이
/// 개별 선언하던 로컬 색상 상수(`_primaryColor` 등)를 하나의 출처로 통합한다.
/// 값(hex)은 기존 사용값을 1:1 그대로 유지하므로 색상 변경 없이 참조만 일원화된다.
abstract final class AppColors {
  // ---- Brand ----
  /// 브랜드 퍼플(주요 포인트/버튼/선택 강조).
  static const Color primary = Color(0xFF7F4FFF);

  /// 눌림/강조 상태의 진한 퍼플.
  static const Color primaryStrong = Color(0xFF7025FF);

  /// 옅은 퍼플(보조 강조).
  static const Color primarySoft = Color(0xFFC7B3FF);

  /// 퍼플 틴트 배경(배지/하이라이트 영역 배경).
  static const Color primarySurface = Color(0xFFF2EFFF);

  // ---- Text ----
  /// 강한 본문/제목 텍스트.
  static const Color textStrong = Color(0xFF30343C);

  /// 톤 다운된 본문 텍스트.
  static const Color textMuted = Color(0xFF51565F);

  /// 보조 텍스트(라벨/설명).
  static const Color textSecondary = Color(0xFF87909E);

  /// 3차 텍스트(포인트/캡션 등).
  static const Color textTertiary = Color(0xFF6C737F);

  /// 비활성/약한 텍스트.
  static const Color textDisabled = Color(0xFF909AA9);

  /// 입력 필드 플레이스홀더 및 비활성 전경.
  static const Color placeholder = Color(0xFFA2ADBE);

  // ---- Line / Border ----
  /// 기본 라인/보더.
  static const Color border = Color(0xFFD6DBE4);

  /// 옅은 보더(비활성 버튼 배경/구분선 겸용).
  static const Color borderLight = Color(0xFFE8EBF1);

  /// 미세 보더.
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // ---- Background ----
  /// 회색 배경(섹션 구분 바/아이콘 배경).
  static const Color bgGray = Color(0xFFF4F6F8);

  /// 섹션 구분 갭 배경(흰 섹션 사이). 디자인 토큰 #F4F6F8은 기기에서 흰색과
  /// 구분이 거의 안 되어, 디자인 렌더의 "보이는 밝은 회색"에 맞춘 값.
  static const Color sectionGap = Color(0xFFEDF0F4);

  /// 은은한 배경.
  static const Color bgSoft = Color(0xFFF8F9FB);

  /// 카드/기본 흰색 배경.
  static const Color white = Color(0xFFFFFFFF);

  // ---- Status / Accent ----
  /// 오류/필수 표시(빨강 dot).
  static const Color error = Color(0xFFFF3D3D);

  /// 옅은 오류 강조(빨강).
  static const Color errorSoft = Color(0xFFFF5F5F);

  /// 대표 펫/배지 강조(골드).
  static const Color gold = Color(0xFFF4C21B);

  /// 점/구분 포인트(연한 청회색).
  static const Color dot = Color(0xFFB4C0D3);
}
