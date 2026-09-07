import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class NurimListButton extends StatelessWidget {
  const NurimListButton({
    super.key,
    required this.title,
    this.onPressed,
    this.leading,
    this.showTrailingIcon = true,
    this.enabled = true,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool showTrailingIcon;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  static const Color _backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onPressed != null;

    return Material(
      color: _backgroundColor,
      child: InkWell(
        onTap: effectiveEnabled ? onPressed : null,
        child: Container(
          // 피그마 List button(207:5589)은 높이 56 · 상하 패딩 16 이고
          // 안쪽 내용(화살표 24)이 16+24+16 = 56 으로 딱 맞는다.
          // 고정 높이 56 에 하단 보더 1 이 컨텐츠 박스를 1 먹어서 내용이
          // 눌려 있었다(서비스 약관은 패딩 18 이라 5 나 눌려 글자·화살표가
          // 잘려 보였다 — 검수 26행 ①). 최소 높이로 바꿔 눌리지 않게 하고,
          // 글자를 키운 사용자에게도 같이 늘어나게 한다.
          constraints: const BoxConstraints(minHeight: 56),
          padding: padding,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 16)],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: -0.66,
                    color: enabled ? AppColors.textMuted : AppColors.placeholder,
                  ),
                ),
              ),
              if (showTrailingIcon) ...[
                const SizedBox(width: 16),
                // Figma Icon/ArrowRight/24 (#909AA9), 비활성 시에만 색 교체
                SvgPicture.asset(
                  'assets/images/ic_arrow_right_24.svg',
                  width: 24,
                  height: 24,
                  colorFilter: enabled
                      ? null
                      : const ColorFilter.mode(
                          AppColors.placeholder,
                          BlendMode.srcIn,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

