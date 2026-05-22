import 'package:flutter/material.dart';

class NurimMyInfoCard extends StatelessWidget {
  const NurimMyInfoCard({
    super.key,
    required this.email,
    this.title = '내 정보',
    this.actionLabel = '관리',
    this.onActionPressed,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final String title;
  final String email;
  final String actionLabel;
  final VoidCallback? onActionPressed;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  static const Color _backgroundColor = Colors.white;
  static const Color _borderColor = Color(0xFFE8EBF1);
  static const Color _titleColor = Color(0xFF30343C);
  static const Color _bodyColor = Color(0xFF5B6472);
  static const Color _disabledColor = Color(0xFFA2ADBE);

  @override
  Widget build(BuildContext context) {
    final trimmedEmail = email.trim();
    final effectiveEnabled = enabled && onActionPressed != null;

    return Padding(
      padding: padding,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: -0.66,
                      color: enabled ? _titleColor : _disabledColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trimmedEmail.isEmpty ? '-' : trimmedEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      letterSpacing: -0.66,
                      color: enabled ? _bodyColor : _disabledColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _MyInfoActionButton(
              label: actionLabel,
              onPressed: effectiveEnabled ? onActionPressed : null,
              enabled: enabled,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyInfoActionButton extends StatelessWidget {
  const _MyInfoActionButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onPressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: effectiveEnabled ? onPressed : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 50),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? const Color(0xFFD6DBE4) : const Color(0xFFE8EBF1),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.5,
            letterSpacing: -0.66,
            color: enabled
                ? NurimMyInfoCard._titleColor
                : NurimMyInfoCard._disabledColor,
          ),
        ),
      ),
    );
  }
}
