import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/list_button.dart';
import '../../../core/widgets/page_header.dart';
import '../../signup/application/signup_providers.dart';
import '../../signup/terms_detail_screen.dart';

/// 마이페이지 > 서비스 약관 목록 (Figma USR-AUT-056)
///
/// 활성 약관(activeTermsProvider)을 목록으로 보여주고, 항목을 탭하면
/// 약관 상세 화면(Figma USR-AUT-051~055)으로 이동한다. 약관 내용은
/// 백엔드에서 받아온 값(content)을 그대로 렌더한다.
class ServiceTermsScreen extends ConsumerWidget {
  const ServiceTermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsState = ref.watch(activeTermsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: NurimPageHeader(
        title: '서비스 약관',
        showDivider: true, // Figma 약관 화면은 헤더 아래 구분선 있음(USR-AUT-051~056)
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: termsState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stackTrace) => _ErrorView(
            onRetry: () => ref.invalidate(activeTermsProvider),
          ),
          data: (terms) {
            if (terms.isEmpty) {
              return const Center(
                child: Text(
                  '표시할 약관이 없습니다.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: terms.length,
              // NurimListButton 이 이미 하단 구분선을 그리는데 그 위에
              // Divider 를 하나 더 얹어 회색선이 2 로 보였다(검수 26행 ②).
              itemBuilder: (context, index) {
                final term = terms[index];
                return NurimListButton(
                  title: term.termsName,
                  // 피그마 List button 은 상하좌우 16. 20/18 이라 내용이 눌렸다.
                  padding: const EdgeInsets.all(16),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TermsDetailScreen(term: term),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '약관을 불러오지 못했습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
