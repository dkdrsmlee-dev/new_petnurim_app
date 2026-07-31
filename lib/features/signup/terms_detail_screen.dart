import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/page_header.dart';
import 'domain/signup_terms.dart';

/// 약관 상세 화면 (Figma USR-AUT-051~055).
///
/// 회원가입 약관 동의 화면과 마이페이지 서비스 약관에서 공용으로 사용한다.
/// 본문(content)은 백엔드에서 받아온 HTML 을 [HtmlWidget] 으로 렌더한다.
class TermsDetailScreen extends StatelessWidget {
  const TermsDetailScreen({super.key, required this.term});

  final ActiveTerm term;

  @override
  Widget build(BuildContext context) {
    final content = term.content.trim();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: term.termsName,
        showDivider: false,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: content.isEmpty
                    ? const Text(
                        '약관 본문이 비어 있습니다.',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                      )
                    : HtmlWidget(
                        content,
                        textStyle: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                          height: 1.6,
                          letterSpacing: -0.4,
                        ),
                      ),
              ),
            ),
            // 하단 확인 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.66,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
