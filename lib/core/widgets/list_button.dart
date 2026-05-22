import 'package:flutter/material.dart';

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
  static const Color _borderColor = Color(0xFFE8EBF1);
  static const Color _textColor = Color(0xFF30343C);
  static const Color _disabledTextColor = Color(0xFFA2ADBE);
  static const Color _iconColor = Color(0xFF87909E);

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onPressed != null;

    return Material(
      color: _backgroundColor,
      child: InkWell(
        onTap: effectiveEnabled ? onPressed : null,
        child: Container(
          height: 56,
          padding: padding,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _borderColor)),
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
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: -0.66,
                    color: enabled ? _textColor : _disabledTextColor,
                  ),
                ),
              ),
              if (showTrailingIcon) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: enabled ? _iconColor : _disabledTextColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
