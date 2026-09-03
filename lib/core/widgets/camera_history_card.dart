import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// 촬영 내역 화면 등에서 공동으로 사용하는 펫 및 촬영 정보 요약 카드 위젯 (Figma 582-10375)
class CameraHistoryCardData {
  const CameraHistoryCardData({
    required this.name,
    required this.breed,
    required this.ageText,
    required this.genderText,
    required this.thisMonthCount,
    required this.accumulatedRewards,
    this.isFavorite = false,
    this.imageProvider,
  });

  final String name;
  final String breed;
  final String ageText;
  final String genderText;
  final int thisMonthCount;
  final int accumulatedRewards;
  final bool isFavorite;
  final ImageProvider? imageProvider;
}

class CameraHistoryCard extends StatelessWidget {
  const CameraHistoryCard({
    super.key,
    required this.data,
  });

  final CameraHistoryCardData data;


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ① 반려동물 정보 영역 (아바타 + 뱃지 + 이름 + 세부스펙)
          _PetInfoSection(data: data),
          
          const SizedBox(height: 16),

          // ② 이번 달 미션 참여 및 리워드 이력 정보 카드
          _MissionHistoryCard(
            thisMonthCount: data.thisMonthCount,
            accumulatedRewards: data.accumulatedRewards,
          ),
        ],
      ),
    );
  }
}

// ─── 내부 서브 위젯 ──────────────────────────────────────────

class _PetInfoSection extends StatelessWidget {
  const _PetInfoSection({required this.data});
  final CameraHistoryCardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 반려동물 아바타 (즐겨찾기 스타 뱃지 포함 Stack)
        Stack(
          clipBehavior: Clip.none,
          children: [
            _CircularAvatar(imageProvider: data.imageProvider),
            if (data.isFavorite)
              Positioned(
                bottom: 0,
                right: 0,
                child: SvgPicture.asset(
                  // Figma Icon/Favorite/24
                  'assets/images/ic_favorite.svg',
                  width: 24,
                  height: 24,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6), // Figma: 사진 ↔ 이름 6

        // 반려동물 이름
        Text(
          data.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
            letterSpacing: -0.66,
            color: AppColors.textMuted,
          ),
        ),

        // 반려동물 나이 · 품종 · 성별 정보 행
        _PetDetailsRow(
          breed: data.breed,
          ageText: data.ageText,
          genderText: data.genderText,
        ),
      ],
    );
  }
}

class _CircularAvatar extends StatelessWidget {
  const _CircularAvatar({required this.imageProvider});
  final ImageProvider? imageProvider;

  static const Widget _fallbackIcon = Icon(
    Icons.pets,
    size: 36,
    color: AppColors.dot,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgGray,
        // Figma: 보더 없음
      ),
      child: ClipOval(
        // 이미지가 없거나 로드 실패(예: 404) 시 동일한 발바닥 아이콘으로 폴백
        child: imageProvider != null
            ? Image(
                image: imageProvider!,
                fit: BoxFit.cover,
                width: 70,
                height: 70,
                errorBuilder: (_, __, ___) => _fallbackIcon,
              )
            : _fallbackIcon,
      ),
    );
  }
}

class _PetDetailsRow extends StatelessWidget {
  const _PetDetailsRow({
    required this.breed,
    required this.ageText,
    required this.genderText,
  });

  final String breed;
  final String ageText;
  final String genderText;

  static const TextStyle _style = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: -0.66,
    color: AppColors.textDisabled,
  );

  @override
  Widget build(BuildContext context) {
    final items = [ageText, breed, genderText]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      children.add(
        Text(items[i], style: _style),
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

class _MissionHistoryCard extends StatelessWidget {
  const _MissionHistoryCard({
    required this.thisMonthCount,
    required this.accumulatedRewards,
  });

  final int thisMonthCount;
  final int accumulatedRewards;

  // 피그마 원본 Icon/Calendarcheck/16 벡터 패스
  static const String _calendarCheckSvg = '''
<svg viewBox="0 0 13 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M1.41667 4.69284H10.75M2.62302 0.75V1.77869M9.41667 0.75V1.77857M9.41667 1.77857H2.75C1.64543 1.77857 0.75 2.69958 0.75 3.8357V10.6929C0.75 11.829 1.64543 12.75 2.75 12.75H9.41667C10.5212 12.75 11.4167 11.829 11.4167 10.6929L11.4167 3.8357C11.4167 2.69958 10.5212 1.77857 9.41667 1.77857ZM4.41667 8.80713L5.41667 9.8357L7.75 7.43571" stroke="#51565F" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  // 피그마 원본 Icon/Coin/16 벡터 패스
  static const String _coinSvg = '''
<svg viewBox="0 0 20 17" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M18.8125 6.75V10.6875C18.8125 11.8598 18.023 13.0877 16.3926 14.0752C14.7806 15.0514 12.4898 15.6875 9.90625 15.6875C7.3227 15.6875 5.03186 15.0514 3.41992 14.0752C1.78949 13.0877 1 11.8598 1 10.6875V6.75H18.8125Z" stroke="#51565F" stroke-width="2"/>
  <path d="M14.9375 10.375V14.5" stroke="#51565F" stroke-width="2" stroke-linecap="round"/>
  <path d="M4.75 10.375V14.5" stroke="#51565F" stroke-width="2" stroke-linecap="round"/>
  <path d="M9.90625 10.375V14.5" stroke="#51565F" stroke-width="2" stroke-linecap="round"/>
  <path d="M9.90625 1C12.4898 1 14.7806 1.63613 16.3926 2.6123C18.023 3.59982 18.8125 4.82774 18.8125 6C18.8125 7.17226 18.023 8.40018 16.3926 9.3877C14.7806 10.3639 12.4898 11 9.90625 11C7.3227 11 5.03186 10.3639 3.41992 9.3877C1.78949 8.40018 1 7.17226 1 6C1 4.82774 1.78949 3.59982 3.41992 2.6123C5.03186 1.63613 7.3227 1 9.90625 1Z" fill="white" stroke="#51565F" stroke-width="2"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textMuted.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 이번 달 참여 횟수
          _HistoryItemRow(
            iconWidget: SvgPicture.string(_calendarCheckSvg),
            label: '이번 달 참여',
            value: '$thisMonthCount회',
          ),
          const SizedBox(height: 12),
          // Row 2: 누적 촬영 리워드
          _HistoryItemRow(
            // 피그마 Icon/Coin/16: 16 박스 안에 13.208 x 11.125 로 들어간다.
            // viewBox(20x17)를 16 폭에 맞추면 21% 커져 회색 원을 꽉 채운다.
            iconWidget: Center(
              child: SizedBox(
                width: 13.208,
                height: 11.125,
                child: SvgPicture.string(_coinSvg, fit: BoxFit.fill),
              ),
            ),
            label: '누적 촬영 리워드',
            value: '${accumulatedRewards}PR',
          ),
        ],
      ),
    );
  }
}

class _HistoryItemRow extends StatelessWidget {
  const _HistoryItemRow({
    required this.iconWidget,
    required this.label,
    required this.value,
  });

  final Widget iconWidget;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 원형 배경 속 아이콘
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.bgGray,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: iconWidget,
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 설명 라벨 텍스트
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: -0.66,
            ),
          ),
        ),
        // 수치 정보
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: -0.66,
          ),
        ),
      ],
    );
  }
}
