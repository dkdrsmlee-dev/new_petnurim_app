import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/nurim_toast.dart';

/// 앱 전역에서 일관된 토스트 메시지를 출력하기 위한 유틸리티 클래스.
class ToastUtil {
  static OverlayEntry? _currentEntry;

  /// 지정된 메시지를 담은 토스트를 화면 하단(GNB 위쪽)에 띄웁니다.
  /// 새로운 토스트가 호출되면 기존 토스트는 즉시 소멸합니다.
  static void show(BuildContext context, String message) {
    // 기존에 활성화된 토스트가 있으면 즉시 제거하여 겹침 방지
    _currentEntry?.remove();
    _currentEntry = null;

    final overlayState = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => _ToastOverlayWidget(
        message: message,
        duration: const Duration(milliseconds: 2000), // 2초 노출
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlayState.insert(_currentEntry!);
  }
}

class _ToastOverlayWidget extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastOverlayWidget({
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlayWidget> createState() => _ToastOverlayWidgetState();
}

class _ToastOverlayWidgetState extends State<_ToastOverlayWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // 애니메이션 시간: 250ms
    );
    _controller.forward();

    // 지정된 시간 이후 자동으로 Reverse 애니메이션을 돌리고 토스트 소멸
    _dismissTimer = Timer(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // OS 하단 안전지대나 GNB 위에 정상 노출하기 위해 하단 마진 배치
    return Positioned(
      bottom: 96.0, 
      left: 0,
      right: 0,
      child: NurimToast(
        message: widget.message,
        animation: _controller,
      ),
    );
  }
}
