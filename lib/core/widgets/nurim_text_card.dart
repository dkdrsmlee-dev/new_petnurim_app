import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NurimTextCard extends StatelessWidget {
  const NurimTextCard({
    super.key,
    required this.title,
    required this.content,
    required this.date,
    this.isUnread = false,
    this.isExpanded = false,
    this.hasMore = false,
    this.bullets,
    this.onExpandToggled,
    this.icon,
  });

  /// 알림 카드 제목
  final String title;

  /// 알림 카드 본문 내용
  final String content;

  /// 알림 발생 날짜 (예: 2026.04.08)
  final String date;

  /// 읽지 않은 상태 여부 (true인 경우 우측 상단에 빨간색 N 또는 점 표시)
  final bool isUnread;

  /// 펼쳐진 상태 여부
  final bool isExpanded;

  /// '더보기' 버튼을 노출할 것인지 여부
  final bool hasMore;

  /// 펼쳐졌을 때 노출할 상세 불릿 리스트
  final List<String>? bullets;

  /// 더보기/접기 버튼을 눌렀을 때의 콜백
  final VoidCallback? onExpandToggled;

  /// 좌측에 표시할 커스텀 아이콘 (기본값: SvgPicture.asset('assets/images/icon_bell.svg'))
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A51565F), // #51565F1A
                offset: Offset(0, 0),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 본문 영역
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 아이콘 + 타이틀
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: icon ??
                              SvgPicture.asset(
                                'assets/images/icon_bell.svg',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF30343C),
                                  BlendMode.srcIn,
                                ),
                              ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 16,
                              fontWeight: FontWeight.w700, // Bold
                              color: Color(0xFF30343C),
                              height: 1.4,
                              letterSpacing: -0.66,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 본문 텍스트
                    Text(
                      content,
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w400, // Regular
                        color: Color(0xFF6C737F),
                        height: 1.4,
                        letterSpacing: -0.66,
                      ),
                    ),

                    // 불릿 상세 정보 (펼쳐진 상태이고 정보가 존재할 때만 표시)
                    if (isExpanded && bullets != null && bullets!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...bullets!.map((bullet) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 8, right: 6),
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6C737F),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF6C737F),
                                      height: 1.4,
                                      letterSpacing: -0.66,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 8),

                    // 날짜
                    Text(
                      date,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFA2ADBE),
                        letterSpacing: -0.66,
                      ),
                    ),
                  ],
                ),
              ),

              // 하단 더보기 / 접기 버튼
              if (hasMore) ...[
                Container(height: 1, color: const Color(0xFFF4F6F8)),
                InkWell(
                  onTap: onExpandToggled,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isExpanded ? '접기' : '더보기',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            fontWeight: FontWeight.w500, // Medium
                            color: Color(0xFF87909E),
                            letterSpacing: -0.66,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: const Color(0xFF87909E),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 안읽음 표시 빨간 점 (Figma: 우측 상단 16px 여백 위치)
        if (isUnread)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5F5F),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
