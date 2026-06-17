import 'package:flutter/material.dart';

class EdgeButtonDialog extends StatelessWidget {
  const EdgeButtonDialog({
    super.key,
    required this.title,
    this.content,
    this.cancelText,
    required this.confirmText,
    this.onCancel,
    required this.onConfirm,
    this.topWidget,
    this.cancelBgColor,
    this.cancelTextColor,
    this.confirmBgColor,
    this.confirmTextColor,
  });

  final String title;
  final String? content;
  final String? cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;
  final Widget? topWidget;
  final Color? cancelBgColor;
  final Color? cancelTextColor;
  final Color? confirmBgColor;
  final Color? confirmTextColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      clipBehavior: Clip.antiAlias, // 모달의 둥근 모서리에 맞춰 하단 버튼이 잘리도록 설정
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: 344,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (topWidget != null) ...[
                    topWidget!,
                    const SizedBox(height: 16),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 20,
                      fontWeight: FontWeight.w600, // SemiBold
                      color: Color(0xFF30343C),
                      height: 1.4,
                      letterSpacing: -0.66,
                    ),
                  ),
                  if (content != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      content!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w500, // Medium
                        color: Color(0xFF87909E),
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                if (cancelText != null)
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: TextButton(
                        onPressed: onCancel ?? () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: cancelBgColor ?? const Color(0xFFE8EBF1),
                          foregroundColor: cancelTextColor ?? const Color(0xFF6C737F),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          cancelText!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: cancelTextColor ?? const Color(0xFF6C737F),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: confirmBgColor ?? const Color(0xFF7F4FFF),
                        foregroundColor: confirmTextColor ?? Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        confirmText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: confirmTextColor ?? Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
