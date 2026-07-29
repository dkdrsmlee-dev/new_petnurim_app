import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_colors.dart';

/// KCP 본인인증 WebView 화면.
///
/// [callUrl](= identity-verification/request 응답) 을 로드해 KCP 인증창을 띄우고,
/// 인증 완료 후 WebView 가 `/api/v1/identity-verification/kcp/callback` 로 이동하는
/// 것을 감지하면 화면을 닫으며 `true` 를 반환한다. 사용자가 닫으면 `false`.
///
/// 결과 복호화·CI/DI 취득·세션 반영은 전부 백엔드(콜백 URL)가 처리하므로,
/// 앱은 콜백 URL 도달만 감지하면 된다.
class KcpCertWebViewScreen extends StatefulWidget {
  const KcpCertWebViewScreen({super.key, required this.webViewUrl});

  /// 백엔드가 내려준 WebView 진입 URL(HTML Auto-Submit → KCP 인증창)
  final String webViewUrl;

  /// KCP 결과가 전달되는 백엔드 콜백 경로(이 경로 도달 = 인증 절차 종료)
  static const String _callbackPath = '/identity-verification/kcp/callback';

  @override
  State<KcpCertWebViewScreen> createState() => _KcpCertWebViewScreenState();
}

class _KcpCertWebViewScreenState extends State<KcpCertWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false; // 중복 pop 방지

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;

            // 1) 백엔드 콜백 도달 → 인증 절차 종료(성공 처리)
            if (url.contains(KcpCertWebViewScreen._callbackPath)) {
              _finish(true);
              return NavigationDecision.prevent;
            }

            // 2) http/https 는 WebView 내에서 로드
            if (url.startsWith('http://') || url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }

            // 3) 그 외 스킴(intent://, 통신사 PASS 앱 등)
            //    현재는 WebView 로드만 차단. 통신사 앱 호출이 필요하면
            //    url_launcher 로 외부 실행 처리를 추후 보강한다.
            debugPrint('[KcpCert] 비-http 스킴(추후 외부실행 처리 필요): $url');
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) {
            // 콜백 URL 은 KCP 결과 페이지의 폼 POST 로 진입하는데,
            // Android 의 onNavigationRequest 는 POST 네비게이션에서 호출되지
            // 않으므로 여기서도 콜백 도달을 감지해 화면을 종료한다.
            if (url.contains(KcpCertWebViewScreen._callbackPath)) {
              _finish(true);
              return;
            }
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.webViewUrl));
  }

  void _finish(bool success) {
    if (_finished) return;
    _finished = true;
    debugPrint('[KcpCert] 인증 절차 종료 (success=$success)');
    if (mounted) Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 뒤로가기 시 취소(false) 반환
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            '본인인증',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 24),
            onPressed: () => _finish(false),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
