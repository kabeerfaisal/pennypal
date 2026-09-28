import 'package:flutter/material.dart';

/// A confirmation dialog that cannot overflow.
///
/// [AlertDialog] stacks the title, content and actions in one column with no
/// scrolling, so a long message or a large system font pushes the buttons off
/// the bottom of the screen. This uses a plain [Dialog] so the body can scroll
/// inside a bounded area while the buttons stay pinned and visible.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final Color color;
  final IconData? icon;

  /// A field shown under the message, e.g. a reason for suspending an account.
  final Widget? field;

  const ConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.color = const Color(0xFFDC2626),
    this.icon,
    this.field,
  });

  /// Shows the dialog and resolves to true only when confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color color = const Color(0xFFDC2626),
    IconData? icon,
    Widget? field,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        color: color,
        icon: icon,
        field: field,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    // What is left once the keyboard has taken its slice. The body scrolls
    // inside this, the buttons do not move.
    final available = media.size.height - media.viewInsets.bottom;
    final bodyMax = (available * 0.55).clamp(100.0, 400.0).toDouble();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              // The cap goes on the scroll view, not on the column inside it.
              // Bounding the column would make it overflow rather than let the
              // viewport scroll, which is the bug this dialog exists to avoid.
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: bodyMax),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (icon != null) ...[
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 28),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      if (field != null) ...[
                        const SizedBox(height: 16),
                        field!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Pinned footer. Both buttons are Expanded so two long labels
            // shrink inside their halves instead of overflowing the row.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        cancelLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        minimumSize: const Size(0, 46),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        confirmLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
