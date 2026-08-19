import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _callbackReached = false; // KCP 결과 콜백 진입 감지(종료는 로드 완료까지 대기)
  bool _installPromptShowing = false; // 설치 안내 다이얼로그 중복 방지

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;

            // 1) 백엔드 콜백(KCP 결과 전달) 및 일반 http/https 는 WebView 에서 그대로 로드한다.
            //    콜백은 KCP 결과 페이지의 폼 POST 로 진입하는데, iOS(WKWebView)는 POST
            //    네비게이션에서도 onNavigationRequest 가 호출된다. 여기서 prevent 하면 KCP
            //    결과를 백엔드로 전달하는 그 POST 자체가 취소되어 인증이 서버에 기록되지
            //    않는다(→ 이후 휴대폰변경 PATCH 404). 따라서 콜백으로의 이동도 막지 않고
            //    진행시키며, 완료 감지는 onPageFinished 의 콜백 로드 완료로 처리한다.
            //    (Android 는 POST 에서 onNavigationRequest 가 호출되지 않으므로 동작 변화 없음.)
            if (url.startsWith('http://') || url.startsWith('https://')) {
              return NavigationDecision.navigate;
            }

            // about:blank 은 KCP 서브프레임/중간 전환에서 발생하는 빈 페이지다. 외부 앱
            //   실행 대상이 아니므로 외부실행 없이 막기만 한다(오해성 실행실패 스낵바 방지).
            if (url.startsWith('about:')) {
              return NavigationDecision.prevent;
            }

            // 2) 그 외 스킴(intent://, 통신사 PASS 앱 등) → 외부 앱으로 실행.
            //    WebView 는 http(s) 만 로드하므로, 통신사 PASS 앱 실행 스킴은
            //    외부 앱 실행으로 위임한다(미설치 시 마켓/웹 폴백).
            debugPrint('[KcpCert] 외부 스킴 감지 → 외부 실행 시도: $url');
            _launchExternal(url);
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) {
            // 콜백 URL(KCP 결과 전달) 진입을 감지하되, 여기서 바로 종료하지 않는다.
            // onPageStarted 는 콜백 POST 가 '시작'된 시점(응답 수신 전)이라, 이때 화면을
            // 닫고 changePhone 을 호출하면 백엔드가 KCP 결과를 기록하기 전에 변경 API 가
            // 먼저 도착해 404(IDENTITY_VERIFICATION.NOT_FOUND) 가 난다(iOS 에서 재현되는
            // 타이밍 레이스). 따라서 진입만 표시하고, 실제 종료는 로드 '완료'(onPageFinished)
            // 시점으로 미뤄 백엔드 기록 완료를 보장한다.
            if (url.contains(KcpCertWebViewScreen._callbackPath)) {
              _callbackReached = true;
            }
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            // 콜백 진입 이후 첫 로드 완료 = 백엔드가 KCP 결과를 기록 완료한 시점 → 이제 종료.
            //   (콜백이 리다이렉트를 반환하더라도 최종 페이지 로드 완료까지 기다리므로 안전)
            if (_callbackReached) {
              _finish(true);
              return;
            }
            if (mounted) setState(() => _loading = false);
          },
          // KCP 의 통신사 PASS 앱 실행은 intent:// 스킴으로 시도되는데,
          // Android WebView 는 이를 onNavigationRequest 로 넘기지 않고
          // ERR_UNKNOWN_URL_SCHEME 에러로 던진다. 여기서 외부 앱 실행으로 위임한다.
          onWebResourceError: (error) {
            final failingUrl = error.url ?? '';
            if (failingUrl.isNotEmpty &&
                !failingUrl.startsWith('http://') &&
                !failingUrl.startsWith('https://') &&
                !failingUrl.startsWith('about:')) {
              debugPrint('[KcpCert] 알 수 없는 스킴(에러 경로) → 외부 실행: $failingUrl');
              _launchExternal(failingUrl);
            }
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

  /// intent:// 등 비-http 스킴을 외부 앱(통신사 PASS 등)으로 실행한다.
  /// 실행 우선순위(한국 앱 표준):
  ///   1) 앱 설치됨 → 앱 실행
  ///   2) 미설치 + intent 에 browser_fallback_url 있음 → 그 URL 을 WebView 로 로드
  ///   3) 미설치 + package 있음 → 설치 안내 후 마켓(플레이스토어)으로 이동
  ///   4) 그 외 → 문자(SMS) 인증 유도 안내
  ///
  /// 주의: url_launcher 는 intent:// 문법을 파싱하지 못하므로, intent:// 는
  /// 내부 `scheme=` 을 추출해 실제 앱 스킴 URL(예: tauthlink://...) 로
  /// 재구성한 뒤 실행한다([_toLaunchableUri]).
  Future<void> _launchExternal(String url) async {
    final uri = _toLaunchableUri(url);
    if (uri != null) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return; // 1) 앱 실행 성공
      } catch (error) {
        debugPrint('[KcpCert] 외부 앱 실행 실패: $error');
      }
    }

    // 2) intent:// 의 browser_fallback_url 이 있으면 WebView 로 로드
    final fallbackUrl = _extractIntentFallbackUrl(url);
    if (fallbackUrl != null) {
      debugPrint('[KcpCert] 폴백 URL 로드: $fallbackUrl');
      _controller.loadRequest(Uri.parse(fallbackUrl));
      return;
    }

    // 3) fallback_url 이 없으면 intent 의 package 를 추출해 마켓(설치 페이지)으로 안내
    final packageName = _extractIntentPackage(url);
    if (packageName != null && packageName.isNotEmpty) {
      await _promptInstallFromMarket(packageName);
      return;
    }

    // 4) 방법이 없으면 문자(SMS) 인증 유도 안내
    _showLaunchFailSnackBar();
  }

  /// url_launcher 로 실행 가능한 URI 를 만든다.
  /// - intent:// 는 파싱 불가하므로 내부 `scheme=` 으로 커스텀 스킴 URL 을 재구성
  ///   (예: intent://sktauth?x=1#Intent;scheme=tauthlink;...;end → tauthlink://sktauth?x=1)
  /// - 그 외 커스텀 스킴은 그대로 사용
  Uri? _toLaunchableUri(String url) {
    if (!url.startsWith('intent://')) {
      return Uri.tryParse(url);
    }
    final scheme = _extractIntentScheme(url);
    if (scheme == null || scheme.isEmpty) {
      return null;
    }
    final hashIndex = url.indexOf('#Intent');
    final body = url.substring(
      'intent://'.length,
      hashIndex < 0 ? url.length : hashIndex,
    );
    return Uri.tryParse('$scheme://$body');
  }

  /// intent:// URL 에 포함된 `scheme=` 값을 추출한다(없으면 null).
  String? _extractIntentScheme(String url) {
    final match = RegExp(r'scheme=([^;]+)').firstMatch(url);
    return match?.group(1);
  }

  /// intent:// URL 에 포함된 `S.browser_fallback_url` 값을 추출한다(없으면 null).
  String? _extractIntentFallbackUrl(String url) {
    if (!url.startsWith('intent://')) return null;
    final match = RegExp(
      r'S\.browser_fallback_url=([^;]+)',
    ).firstMatch(url);
    if (match == null) return null;
    return Uri.decodeFull(match.group(1)!);
  }

  /// intent:// URL 에 포함된 `package=` 값을 추출한다(없으면 null).
  String? _extractIntentPackage(String url) {
    if (!url.startsWith('intent://')) return null;
    final match = RegExp(r'package=([^;]+)').firstMatch(url);
    if (match == null) return null;
    return match.group(1);
  }

  /// PASS 앱 미설치 안내 다이얼로그를 띄우고, 동의 시 마켓으로 이동한다.
  Future<void> _promptInstallFromMarket(String packageName) async {
    if (!mounted || _installPromptShowing) return;
    _installPromptShowing = true;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('PASS 앱 설치 필요'),
          content: const Text(
            'PASS 앱이 설치되어 있지 않아요.\n설치 페이지로 이동할까요?\n'
            '(문자(SMS) 인증도 이용할 수 있어요.)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('설치하기'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _openMarket(packageName);
      }
    } finally {
      _installPromptShowing = false;
    }
  }

  /// 플레이스토어 앱(market://) → 실패 시 웹(play.google.com) 순으로 설치 페이지를 연다.
  Future<void> _openMarket(String packageName) async {
    final marketUri = Uri.parse('market://details?id=$packageName');
    try {
      if (await launchUrl(marketUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (error) {
      debugPrint('[KcpCert] 마켓(market://) 실행 실패: $error');
    }

    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );
    try {
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (error) {
      debugPrint('[KcpCert] 플레이스토어 웹 실행 실패: $error');
    }

    _showLaunchFailSnackBar();
  }

  void _showLaunchFailSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'PASS 앱을 실행할 수 없어요. PASS 앱을 설치하거나 문자(SMS) 인증을 이용해 주세요.',
        ),
      ),
    );
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
