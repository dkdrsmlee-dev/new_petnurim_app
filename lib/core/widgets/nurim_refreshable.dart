import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 당겨서 새로고침 공통 래퍼.
///
/// - 브랜드 색 스피너로 통일.
/// - 자식은 스크롤 위젯이어야 하며, 내용이 짧아도(로딩/빈/에러) 당김이 되도록
///   `AlwaysScrollableScrollPhysics` 를 쓰는 것을 권장한다.
///   (짧은 콘텐츠는 [RefreshableCenter] 로 감싸면 화면을 채우면서 당김 가능해짐)
///
/// Riverpod 새로고침은 보통 `onRefresh` 에서 다음 패턴을 쓴다:
/// ```dart
/// onRefresh: () async {
///   ref.invalidate(someProvider);
///   await ref.read(someProvider.future); // 새 데이터 도착까지 스피너 유지
/// }
/// ```
class NurimRefreshable extends StatelessWidget {
  const NurimRefreshable({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// 로딩/빈/에러처럼 짧은 콘텐츠를, 화면 높이만큼 채우면서도 **당김 가능한**
/// 스크롤 영역으로 감싼다. [NurimRefreshable] 의 `.when(loading/error)` 브랜치에서
/// 사용해 모든 상태에서 pull-to-refresh 가 동작하도록 한다.
class RefreshableCenter extends StatelessWidget {
  const RefreshableCenter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
