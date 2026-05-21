import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AddressWebViewScreen extends StatefulWidget {
  const AddressWebViewScreen({super.key});

  @override
  State<AddressWebViewScreen> createState() => _AddressWebViewScreenState();
}

class _AddressWebViewScreenState extends State<AddressWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AddressChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final Map<String, dynamic> data = jsonDecode(message.message);
            final zonecode = data['zonecode'] as String? ?? '';
            final address = data['address'] as String? ?? '';
            if (mounted) {
              // 결과 값을 반환하며 화면을 닫음
              Navigator.of(context).pop({'zonecode': zonecode, 'address': address});
            }
          } catch (e) {
            debugPrint('[AddressWebView] Error decoding message: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('[AddressWebView] Page finished: \$url');
            if (mounted) {
              setState(() {
                _loading = false;
              });
            }
          },
        ),
      )
      ..loadHtmlString(_daumPostcodeHtml, baseUrl: 'https://postcode.map.daum.net');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('우편번호 검색'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

const String _daumPostcodeHtml = '''
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>우편번호 검색</title>
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      background-color: #ffffff;
    }
    #wrap {
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <div id="wrap"></div>

  <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
  <script>
    const element_wrap = document.getElementById('wrap');

    new daum.Postcode({
      oncomplete: function(data) {
        var msg = JSON.stringify({
          zonecode: data.zonecode,
          address: data.roadAddress || data.address || data.jibunAddress
        });
        try {
          if (typeof AddressChannel !== 'undefined' && AddressChannel.postMessage) {
            AddressChannel.postMessage(msg);
          } else if (window.AddressChannel && window.AddressChannel.postMessage) {
            window.AddressChannel.postMessage(msg);
          } else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.AddressChannel) {
            window.webkit.messageHandlers.AddressChannel.postMessage(msg);
          } else {
            console.log("No JS bridge found. Output: " + msg);
          }
        } catch(e) {
          console.error("Failed to post address message: " + e);
        }
      },
      onresize: function(size) {
        element_wrap.style.height = size.height + 'px';
      },
      width: '100%',
      height: '100%'
    }).embed(element_wrap);
  </script>
</body>
</html>
''';
