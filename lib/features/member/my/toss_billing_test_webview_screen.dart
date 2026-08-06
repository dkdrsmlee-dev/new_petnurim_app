import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';

/// 토스페이먼츠 자동결제(빌링) 카드 등록창을 **테스트 모드**로 띄우는 임시 화면.
///
/// 백엔드 PG 연동(상점 clientKey/secretKey, billingKey 발급 API)이 아직 없어,
/// 토스 **공개 테스트 clientKey**로 카드 등록 UI만 미리 확인한다. 실제 billingKey
/// 발급(시크릿키·서버)·카드 저장은 하지 않으며, 카드 입력 후 토스가 successUrl로
/// 리다이렉트하면 그 도달(= authKey 수신)만 감지해 `true`를 반환한다.
///
/// 백엔드가 준비되면 이 화면은 실제 clientKey + 서버 billingKey 발급 흐름으로
/// 교체한다. WebView 콜백 감지 패턴은 휴대폰 변경 `KcpCertWebViewScreen`과 동일.
class TossBillingTestWebViewScreen extends StatefulWidget {
  const TossBillingTestWebViewScreen({super.key});

  // 토스가 카드 등록 완료/실패 시 리다이렉트하는 더미 URL(실제 로드 전에 가로챔).
  static const String _successPath = '/toss/billing/success';
  static const String _failPath = '/toss/billing/fail';

  // 토스페이먼츠 공개 테스트 clientKey(v1 SDK 샘플). 실제 상점 키가 아니며 테스트 전용.
  static const String _testClientKey = 'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq';

  @override
  State<TossBillingTestWebViewScreen> createState() =>
      _TossBillingTestWebViewScreenState();
}

class _TossBillingTestWebViewScreenState
    extends State<TossBillingTestWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  String get _html => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
  html,body{margin:0;height:100%;font-family:-apple-system,BlinkMacSystemFont,'Apple SD Gothic Neo',sans-serif}
  #msg{padding:24px;color:#51565F;font-size:14px;line-height:1.6}
</style>
</head>
<body>
<div id="msg">토스 카드 등록창을 여는 중…</div>
<script src="https://js.tosspayments.com/v1/payment"></script>
<script>
  (function () {
    function show(t){ var m=document.getElementById('msg'); if(m){ m.innerText=t; } }
    try {
      var tp = TossPayments('${TossBillingTestWebViewScreen._testClientKey}');
      tp.requestBillingAuth('카드', {
        customerKey: 'preview-customer-0001',
        successUrl: 'https://petnurim.kr${TossBillingTestWebViewScreen._successPath}',
        failUrl: 'https://petnurim.kr${TossBillingTestWebViewScreen._failPath}'
      }).catch(function (e) {
        show('카드 등록 취소 또는 오류: ' + (e && e.message ? e.message : e));
      });
    } catch (e) {
      show('토스 SDK 오류: ' + e);
    }
  })();
</script>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains(TossBillingTestWebViewScreen._successPath)) {
              _finish(true);
              return NavigationDecision.prevent;
            }
            if (url.contains(TossBillingTestWebViewScreen._failPath)) {
              _finish(false);
              return NavigationDecision.prevent;
            }
            if (url.startsWith('http://') ||
                url.startsWith('https://') ||
                url.startsWith('about:')) {
              return NavigationDecision.navigate;
            }
            // intent:// 등 외부 스킴(앱카드 등)은 외부 앱으로 위임.
            _launchExternal(url);
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) {
            if (url.contains(TossBillingTestWebViewScreen._successPath)) {
              _finish(true);
              return;
            }
            if (url.contains(TossBillingTestWebViewScreen._failPath)) {
              _finish(false);
              return;
            }
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_html, baseUrl: 'https://petnurim.kr');
  }

  void _finish(bool success) {
    if (_finished) return;
    _finished = true;
    if (mounted) Navigator.of(context).pop(success);
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // 외부 앱 실행 실패는 무시(테스트 미리보기 목적).
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(false);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: NurimPageHeader(
          title: '카드 등록 (테스트)',
          onBackPressed: () => _finish(false),
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
