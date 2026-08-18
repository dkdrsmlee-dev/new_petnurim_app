import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_bootstrap.dart';
import '../../../app/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/application/auth_providers.dart';
import 'my_page_view.dart';

/// 마이페이지 화면. 홈 탭이 아니라 **별도 라우트로 push**되는 하위 화면이라
/// 하단 GNB가 보이지 않는다(내 정보 관리·결제수단 등 다른 상세 화면과 일관).
/// 로그아웃 로직도 이 화면이 보유한다.
class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .logout()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // 서버 로그아웃 실패/지연 시에도 로컬 로그아웃은 계속 진행 (best-effort)
    }
    await ref.read(tokenStorageProvider).clearTokens();
    ref.invalidate(appBootstrapStateProvider);
    if (!mounted) return;
    context.go(AppRoutes.authStart);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MyPageView(
          isLoggingOut: _isLoggingOut,
          onLogout: _logout,
          // 뒤로가기: push로 들어왔으면 pop, 아니면(go로 진입) 홈으로.
          onBackToHome: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
    );
  }
}
