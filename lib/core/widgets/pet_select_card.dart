import 'package:flutter/material.dart';

/// 펫 선택 화면에서 사용하는 카드 위젯 (Figma 624-8533)
///
/// 카드를 탭하면 [onTap]이 호출되며,
/// "촬영 내역" 버튼을 탭하면 [onHistoryTap]이 호출됩니다.
class PetSelectCardData {
  const PetSelectCardData({
    required this.name,
    required this.breed,
    required this.ageText,
    required this.genderText,
    this.isFavorite = false,
    this.imageProvider,
  });

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
  });

  final PetSelectCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onHistoryTap;

  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _borderColor = Color(0xFFD6DBE4);
  static const Color _nameColor = Color(0xFF51565F);
  static const Color _mutedColor = Color(0xFF909AA9);
  static const Color _historyColor = Color(0xFF87909E);
  static const Color _favBadgeBg = Color(0xFFF0C119);

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
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 1),
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
                                    fontFamily: 'Pretendard',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    letterSpacing: -0.66,
                                    color: _nameColor,
                                  ),
                                ),
                              ),
                              if (data.isFavorite) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: _favBadgeBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 촬영 내역 버튼
                        GestureDetector(
                          onTap: onHistoryTap,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '촬영 내역',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  letterSpacing: -0.66,
                                  color: _historyColor,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: _mutedColor,
                              ),
                            ],
                          ),
                        ),
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
    return ClipOval(
      child: Container(
        width: 48,
        height: 48,
        color: const Color(0xFFA9A9A9),
        child: imageProvider != null
            ? Image(image: imageProvider!, fit: BoxFit.cover)
            : const Icon(Icons.pets, size: 24, color: Colors.white),
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
    fontFamily: 'Pretendard',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.66,
    color: Color(0xFF909AA9),
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
              color: Color(0xFFB4C0D3),
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
