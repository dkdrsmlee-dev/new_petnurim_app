import 'package:flutter/material.dart';

class NurimInfoRow extends StatelessWidget {
  const NurimInfoRow({
    super.key,
    required this.title,
    this.infoText,
    this.subText,
    this.showSubText = true,
    this.showTrailingIcon = true,
    this.onPressed,
    this.leftButtonText,
    this.onLeftButtonPressed,
    this.rightButtonText,
    this.onRightButtonPressed,
    this.trailing,
    this.enabled = true,
    this.showDivider = true,
    this.minHeight = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  const NurimInfoRow.type1({
    super.key,
    required this.title,
    this.onPressed,
    this.enabled = true,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  }) : infoText = null,
       subText = null,
       showSubText = false,
       showTrailingIcon = false,
       leftButtonText = null,
       onLeftButtonPressed = null,
       rightButtonText = null,
       onRightButtonPressed = null,
       trailing = null,
       minHeight = 57;

  NurimInfoRow.type2({
    super.key,
    required this.title,
    required bool value,
    required ValueChanged<bool> onChanged,
    this.enabled = true,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  }) : infoText = null,
       subText = null,
       showSubText = false,
       showTrailingIcon = false,
       onPressed = null,
       leftButtonText = null,
       onLeftButtonPressed = null,
       rightButtonText = null,
       onRightButtonPressed = null,
       trailing = _InfoRowSwitch(
         value: value,
         onChanged: onChanged,
         enabled: enabled,
       ),
       minHeight = 54;

  NurimInfoRow.type3({
    super.key,
    required this.title,
    required this.subText,
    required bool value,
    required ValueChanged<bool> onChanged,
    this.enabled = true,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  }) : infoText = null,
       showSubText = true,
       showTrailingIcon = false,
       onPressed = null,
       leftButtonText = null,
       onLeftButtonPressed = null,
       rightButtonText = null,
       onRightButtonPressed = null,
       trailing = _InfoRowSwitch(
         value: value,
         onChanged: onChanged,
         enabled: enabled,
       ),
       minHeight = 72;

  NurimInfoRow.type4({
    super.key,
    required this.title,
    required String actionLabel,
    VoidCallback? onActionPressed,
    this.enabled = true,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  }) : infoText = null,
       subText = null,
       showSubText = false,
       showTrailingIcon = false,
       onPressed = null,
       leftButtonText = null,
       onLeftButtonPressed = null,
       rightButtonText = null,
       onRightButtonPressed = null,
       trailing = _InfoRowPillButton(
         label: actionLabel,
         onPressed: onActionPressed,
         enabled: enabled,
       ),
       minHeight = 54;

  final String title;
  final String? infoText;
  final String? subText;
  final bool showSubText;
  final bool showTrailingIcon;
  final VoidCallback? onPressed;
  final String? leftButtonText;
  final VoidCallback? onLeftButtonPressed;
  final String? rightButtonText;
  final VoidCallback? onRightButtonPressed;
  final Widget? trailing;
  final bool enabled;
  final bool showDivider;
  final double minHeight;
  final EdgeInsetsGeometry padding;

  static const Color _backgroundColor = Colors.white;
  static const Color _dividerColor = Color(0xFFE8EBF1);
  static const Color _titleColor = Color(0xFF30343C);
  static const Color _infoColor = Color(0xFF30343C);
  static const Color _subColor = Color(0xFF87909E);
  static const Color _disabledColor = Color(0xFFA2ADBE);

  @override
  Widget build(BuildContext context) {
    final hasInfo = infoText != null && infoText!.trim().isNotEmpty;
    final hasSubText =
        showSubText && subText != null && subText!.trim().isNotEmpty;
    final hasLeftButton =
        leftButtonText != null && leftButtonText!.trim().isNotEmpty;
    final hasRightButton =
        rightButtonText != null && rightButtonText!.trim().isNotEmpty;
    final hasButtons = hasLeftButton || hasRightButton;
    final effectiveEnabled = enabled && onPressed != null;

    return Material(
      color: _backgroundColor,
      child: InkWell(
        onTap: effectiveEnabled ? onPressed : null,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: padding,
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: _dividerColor))
                : null,
          ),
          child: Row(
            crossAxisAlignment: hasButtons
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _InfoTextGroup(
                  title: title,
                  infoText: hasInfo ? infoText!.trim() : null,
                  subText: hasSubText ? subText!.trim() : null,
                  enabled: enabled,
                ),
              ),
              if (hasButtons) ...[
                const SizedBox(width: 16),
                _InfoRowActions(
                  leftButtonText: hasLeftButton ? leftButtonText!.trim() : null,
                  onLeftButtonPressed: onLeftButtonPressed,
                  rightButtonText: hasRightButton
                      ? rightButtonText!.trim()
                      : null,
                  onRightButtonPressed: onRightButtonPressed,
                  enabled: enabled,
                ),
              ] else if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ] else if (showTrailingIcon) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: enabled ? _subColor : _disabledColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTextGroup extends StatelessWidget {
  const _InfoTextGroup({
    required this.title,
    required this.infoText,
    required this.subText,
    required this.enabled,
  });

  final String title;
  final String? infoText;
  final String? subText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasInfo = infoText != null;
    final hasSub = subText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: hasInfo || hasSub
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        Row(
          children: [
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
                  color: enabled
                      ? NurimInfoRow._titleColor
                      : NurimInfoRow._disabledColor,
                ),
              ),
            ),
            if (hasInfo) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  infoText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    letterSpacing: -0.66,
                    color: enabled
                        ? NurimInfoRow._infoColor
                        : NurimInfoRow._disabledColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasSub) ...[
          const SizedBox(height: 4),
          Text(
            subText!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: -0.66,
              color: enabled
                  ? NurimInfoRow._subColor
                  : NurimInfoRow._disabledColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRowActions extends StatelessWidget {
  const _InfoRowActions({
    required this.leftButtonText,
    required this.onLeftButtonPressed,
    required this.rightButtonText,
    required this.onRightButtonPressed,
    required this.enabled,
  });

  final String? leftButtonText;
  final VoidCallback? onLeftButtonPressed;
  final String? rightButtonText;
  final VoidCallback? onRightButtonPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leftButtonText != null)
          _InfoRowTextButton(
            label: leftButtonText!,
            onPressed: onLeftButtonPressed,
            enabled: enabled,
          ),
        if (leftButtonText != null && rightButtonText != null)
          const SizedBox(width: 8),
        if (rightButtonText != null)
          _InfoRowTextButton(
            label: rightButtonText!,
            onPressed: onRightButtonPressed,
            enabled: enabled,
          ),
      ],
    );
  }
}

class _InfoRowTextButton extends StatelessWidget {
  const _InfoRowTextButton({
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: -0.66,
            color: enabled
                ? NurimInfoRow._subColor
                : NurimInfoRow._disabledColor,
          ),
        ),
      ),
    );
  }
}

class _InfoRowPillButton extends StatelessWidget {
  const _InfoRowPillButton({
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
        constraints: const BoxConstraints(minWidth: 52),
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
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
            fontWeight: FontWeight.w500,
            height: 1.5,
            letterSpacing: -0.66,
            color: enabled
                ? NurimInfoRow._titleColor
                : NurimInfoRow._disabledColor,
          ),
        ),
      ),
    );
  }
}

class _InfoRowSwitch extends StatelessWidget {
  const _InfoRowSwitch({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 22,
      child: FittedBox(
        fit: BoxFit.fill,
        child: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF7F4FFF),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFD6DBE4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
