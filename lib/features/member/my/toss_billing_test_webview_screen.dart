import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';

/// 토스페이먼츠 자동결제(빌링) 카드 등록창을 **테스트 모드**로 띄우는 임시 화면.
///
/// 토스 **공개 테스트 clientKey**로 카드 등록 UI를 띄우고, 카드 입력 후 토스가
/// successUrl 로 리다이렉트하면 그 URL 에서 **authKey 를 추출해 반환**한다(취소/실패
/// 시 null). 실제 billingKey 발급은 백엔드가 authKey/customerKey 로 처리한다.
///
/// 실 상점 clientKey 가 준비되면 [_testClientKey] 만 교체하면 된다. WebView 콜백
/// 감지 패턴은 휴대폰 변경 `KcpCertWebViewScreen`과 동일.
class TossBillingTestWebViewScreen extends StatefulWidget {
  const TossBillingTestWebViewScreen({super.key, required this.customerKey});

  /// 토스 Billing Auth 에 사용할 CustomerKey(가입 시 백엔드로도 함께 전달).
  final String customerKey;

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
        customerKey: '${widget.customerKey}',
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
              _success(url);
              return NavigationDecision.prevent;
            }
            if (url.contains(TossBillingTestWebViewScreen._failPath)) {
              _cancel();
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
              _success(url);
              return;
            }
            if (url.contains(TossBillingTestWebViewScreen._failPath)) {
              _cancel();
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

  /// 성공 콜백 URL 에서 authKey 를 추출해 반환(가입 API 로 전달).
  void _success(String url) {
    if (_finished) return;
    _finished = true;
    final authKey = Uri.tryParse(url)?.queryParameters['authKey'];
    if (mounted) Navigator.of(context).pop(authKey);
  }

  /// 취소/실패 시 null 반환.
  void _cancel() {
    if (_finished) return;
    _finished = true;
    if (mounted) Navigator.of(context).pop(null);
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
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: NurimPageHeader(
          title: '카드 등록 (테스트)',
          onBackPressed: () => _cancel(),
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
