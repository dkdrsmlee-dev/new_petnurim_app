import 'package:flutter/material.dart';

/// 이미지/콘텐츠 로딩 중 표시하는 셔머(스켈레톤) 플레이스홀더.
///
/// 회색 바탕 위로 밝은 띠가 좌→우로 물결처럼 지나간다. 부모가 모양(원/둥근사각)
/// 을 클립하므로 이 위젯은 영역을 채우기만 하면 된다. 로드가 끝나면
/// [shimmerImageFrameBuilder] 가 실제 이미지로 교체한다.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.borderRadius});

  /// 부모가 클립하지 않는 경우를 위한 선택적 라운딩.
  final BorderRadiusGeometry? borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // 셔머 색상: 국내 표준(Flutter shimmer 패키지)과 동일한 중립 회색.
  // grey.300 바탕 + grey.100 하이라이트로 은은하게.
  static const Color _base = Color(0xFFE0E0E0);
  static const Color _highlight = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            // 표준(shimmer 패키지): 대각선(topLeft→centerRight) 방향에
            // [base,base,highlight,base,base] 5-스톱 → 기울어진 띠가 좌→우로.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: const [_base, _base, _highlight, _base, _base],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: _SlidingGradientTransform(_controller.value),
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/// 그라데이션(하이라이트 띠)을 가로로 슬라이드시켜 물결 효과를 만든다.
/// percent 0→1 동안 -너비 → +너비 로 이동하므로 양 끝(띠가 화면 밖)에서
/// 루프가 반복돼도 이음새가 보이지 않는다.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
  }
}

/// Image 의 `frameBuilder` 로 그대로 넘길 수 있는 재사용 헬퍼.
///
/// 로드 전(`frame == null`)에는 [ShimmerBox] 를, 로드 완료 시 실제 이미지를
/// [AnimatedSwitcher] 로 자연스럽게(250ms) 교체한다. 캐시 히트로 즉시 로드되면
/// (`wasSynchronouslyLoaded`) 셔머 없이 바로 표시한다.
///
/// 부모가 크기를 제한하는(둥근 사각/원형 등 bounded) 영역에서 사용한다.
/// 높이가 정해지지 않은(fitWidth 등) 배너에서는 셔머를 비율 박스로 감싸
/// 개별 frameBuilder 를 작성한다.
Widget shimmerImageFrameBuilder(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded) return child;
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    child: frame == null
        ? const ShimmerBox(key: ValueKey('shimmer'))
        : KeyedSubtree(key: const ValueKey('image'), child: child),
  );
}
