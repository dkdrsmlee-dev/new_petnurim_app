import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// 펫 선택 화면에서 사용하는 카드 위젯 (Figma 624-8533)
///
/// 카드를 탭하면 [onTap]이 호출되며,
/// "촬영 내역" 버튼을 탭하면 [onHistoryTap]이 호출됩니다.
class PetSelectCardData {
  const PetSelectCardData({
    this.petId,
    required this.name,
    required this.breed,
    required this.ageText,
    required this.genderText,
    this.isFavorite = false,
    this.imageProvider,
  });

  /// 백엔드 펫 식별자 (촬영 참여 API 호출에 사용). 하드코딩 예시 데이터에는 없을 수 있음.
  final String? petId;
  final String name;
  final String breed;
  final String ageText;
  final String genderText;
  final bool isFavorite;
  final ImageProvider? imageProvider;
}

class PetSelectCard extends StatelessWidget {
  const PetSelectCard({
    super.key,
    required this.data,
    this.onTap,
    this.onHistoryTap,
    this.showHistory = true,
    this.historyLabel = '촬영 내역',
  });

  final PetSelectCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onHistoryTap;

  /// "내역" 버튼 표시 여부. 출석처럼 펫별 내역이 없으면 false.
  final bool showHistory;

  /// "내역" 버튼 라벨 (기본 "촬영 내역").
  final String historyLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ① 펫 이미지 (원형 48×48)
              _PetAvatar(imageProvider: data.imageProvider),
              const SizedBox(width: 10),

              // ② 텍스트 정보 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 이름 행 + 촬영 내역 버튼
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 이름 + 즐겨찾기 아이콘
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  data.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    letterSpacing: -0.66,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              if (data.isFavorite) ...[
                                const SizedBox(width: 4),
                                // Figma Icon/Favorite/24 (대표펫 배지)
                                SvgPicture.asset(
                                  'assets/images/ic_favorite.svg',
                                  width: 24,
                                  height: 24,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showHistory) ...[
                          const SizedBox(width: 16),

                          // 내역 버튼(촬영 내역 등)
                          GestureDetector(
                            onTap: onHistoryTap,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              // Figma: 버튼 패딩 없음(카드 우측 16 정렬).
                              // 우측만 0으로 두고 좌/상/하는 탭 영역용으로 유지.
                              padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    historyLabel,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                      letterSpacing: -0.66,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  // Figma Icon/ArrowRight/16
                                  SvgPicture.asset(
                                    'assets/images/ic_arrow_right_16.svg',
                                    width: 16,
                                    height: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 품종 · 나이 · 성별 정보 행
                    _InfoRow(
                      breed: data.breed,
                      ageText: data.ageText,
                      genderText: data.genderText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 내부 위젯 ────────────────────────────────────────────

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.imageProvider});
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    // 이미지가 없거나 로드 실패(예: 404) 시 동일한 발바닥 아이콘으로 폴백
    const fallback = Center(
      child: Icon(Icons.pets, size: 24, color: Colors.white),
    );
    return ClipOval(
      child: Container(
        width: 48,
        height: 48,
        color: const Color(0xFFA9A9A9),
        child: imageProvider != null
            ? Image(
                image: imageProvider!,
                fit: BoxFit.cover,
                width: 48,
                height: 48,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.breed,
    required this.ageText,
    required this.genderText,
  });

  final String breed;
  final String ageText;
  final String genderText;

  static const TextStyle _style = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.66,
    color: AppColors.textDisabled,
  );

  @override
  Widget build(BuildContext context) {
    final items = [breed, ageText, genderText]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      children.add(
        Flexible(
          child: Text(items[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: _style),
        ),
      );
      if (i < items.length - 1) {
        children.add(const SizedBox(width: 4));
        children.add(
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.dot,
              shape: BoxShape.circle,
            ),
          ),
        );
        children.add(const SizedBox(width: 4));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}
