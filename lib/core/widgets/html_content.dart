import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../theme/app_colors.dart';

/// 관리자가 에디터로 작성해 HTML 로 내려오는 본문(공지사항·자주묻는질문·
/// 1:1문의 답변) 공용 렌더러.
///
/// 세 화면이 같은 서식을 쓰므로 한곳에 모아 둔다.
class NurimHtmlContent extends StatelessWidget {
  const NurimHtmlContent(this.html, {super.key});

  final String html;

  /// 목록(ul/ol)의 왼쪽 들여쓰기.
  ///
  /// flutter_widget_from_html 기본값(40)은 브라우저 관행이라 불릿이 본문보다
  /// 한참 안으로 들어가 가운데로 몰린 것처럼 보였다(검수 27행 ②).
  /// 피그마 Bullet text(644:8460)는 불릿 4 + 간격 6 = 10 이라 그 값을 쓴다.
  static const String _listIndent = '10px';

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      html,
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400, // Regular
        color: AppColors.textMuted,
        height: 1.4,
        letterSpacing: -0.66,
      ),
      customStylesBuilder: (element) {
        switch (element.localName) {
          case 'ul':
          case 'ol':
            return const {
              'padding-inline-start': _listIndent,
              'margin': '0',
            };
          default:
            return null;
        }
      },
    );
  }
}
