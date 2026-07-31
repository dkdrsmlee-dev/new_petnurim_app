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
        showDivider: false,
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
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: terms.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (context, index) {
                final term = terms[index];
                return NurimListButton(
                  title: term.termsName,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
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
