import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pennypal_logo.dart';

/// White rounded surface with the mockup's soft lift.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool lifted;

  /// Draws the card without the shadow, for use inside an already lifted
  /// parent such as a list row.
  final bool borderless;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.lifted = false,
    this.borderless = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = Padding(padding: padding, child: child);

    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: borderless
            ? null
            : (lifted ? AppShadow.lifted(cs) : AppShadow.soft(cs)),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}

/// Titled section with an optional action pinned to the top-right corner.
///
/// The action is a compact outlined pill rather than a bare text button, so it
/// reads as a corner affordance on every section and stays visible against any
/// card behind it.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Expanded takes whatever the action does not need, which is what
          // pins the action to the trailing edge. A Flexible title plus a
          // Spacer instead splits the row three ways and leaves the action
          // floating in the middle.
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.25,
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            // Capped rather than flexible, so a long label ellipsises instead
            // of squeezing the title off a narrow screen.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Material(
                color: isDark
                    ? Colors.white10
                    : cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            actionLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.brandDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          actionIcon,
                          size: 14,
                          color: isDark ? Colors.white : AppColors.brandDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small tinted icon square + label + value, used across the dashboard.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.22)
                  : AppColors.tint(color),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.25,
              color: isDark ? Colors.white60 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill filter chip that fills with a check when selected.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? AppColors.brand
          : (isDark ? AppColors.darkSurface : AppColors.surface),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? AppColors.brand
                  : (isDark ? Colors.white12 : AppColors.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular budget progress with the value in the middle.
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final String centerValue;
  final String caption;
  final Color color;
  final String? badge;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 150,
    required this.centerValue,
    this.caption = '',
    this.color = AppColors.brand,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final track = isDark ? Colors.white12 : AppColors.brandTint;
    final stroke = size * 0.075;
    // The ring stroke sits inside the box, so the label must stay clear of it
    // or long values like "Rs6200 / Rs20000" spill over the circle. The extra
    // proportional padding keeps the text from hugging the stroke.
    final innerWidth = size - stroke * 2 - size * 0.06;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) => CustomPaint(
                painter: _RingPainter(
                  progress: animated,
                  color: color,
                  track: track,
                  stroke: stroke,
                ),
              ),
            ),
          ),
          SizedBox(
            width: innerWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    centerValue,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : AppColors.textMuted,
                    ),
                  ),
                ],
                if (badge != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tint(color),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      badge!,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inner = rect.deflate(stroke / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(inner, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      inner,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// Centred empty state with an optional call to action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : AppColors.brandTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.brand),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDark ? Colors.white60 : AppColors.textMuted,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact "x records • total" strip shown above list content.
class ResultStrip extends StatelessWidget {
  final int count;
  final String totalLabel;
  final String? totalValue;

  const ResultStrip({
    super.key,
    required this.count,
    required this.totalLabel,
    this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white60 : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $count ${count == 1 ? 'record' : 'records'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
          ),
          if (totalValue != null) ...[
            const SizedBox(width: 8),
            Text(
              '$totalLabel: ',
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
            // The amount is the part that must stay readable, so it shrinks
            // last and never wraps onto a second line.
            Flexible(
              child: Text(
                totalValue!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small label + value row used in summary panels.
class LabeledStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;

  const LabeledStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.white60 : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// The in-body top bar of the student dashboard.
///
/// It carries the brand mark, the greeting, the role badge and a working link
/// to the AI advisor. The AI affordance lives here rather than in the app bar
/// so the header row is not crowded, and it is a real tap target rather than a
/// decorative icon that looks tappable but does nothing.
class WelcomeBanner extends StatelessWidget {
  final String name;
  final String role;
  final String symbol;

  /// Opens the AI advisor. When null the AI chip is not shown at all.
  final VoidCallback? onTapAi;

  const WelcomeBanner({
    super.key,
    required this.name,
    required this.role,
    this.symbol = '\$',
    this.onTapAi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandDark, AppColors.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.lifted(Theme.of(context).colorScheme),
      ),
      child: Row(
        children: [
          const PennyPalLogo(
            size: 48,
            background: Colors.white,
            foreground: AppColors.brand,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'PennyPal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  name.isEmpty ? 'Welcome back' : 'Welcome back, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onTapAi != null) _AiChip(onTap: onTapAi!),
        ],
      ),
    );
  }
}

/// The tappable AI entry point. Wrapped in a Material so the ink splash shows,
/// which is what tells the student it actually does something when tapped.
class _AiChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AiChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ask the AI advisor',
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const SizedBox(
            // 44pt is the accessibility minimum for a tap target.
            width: 44,
            height: 44,
            child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Wordmark shown in the light app bar.
class PennyPalWordmark extends StatelessWidget {
  const PennyPalWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PennyPalLogo(
          size: 30,
          background: isDark ? Colors.white10 : AppColors.brandTint,
          foreground: isDark ? Colors.white : AppColors.brand,
        ),
        const SizedBox(width: 9),
        const Text('PennyPal'),
      ],
    );
  }
}

/// Horizontal progress bar with a caption row, as on the budget screen.
class BudgetBar extends StatelessWidget {
  final double value;
  final String leftLabel;
  final String rightLabel;
  final Color color;

  const BudgetBar({
    super.key,
    required this.value,
    required this.leftLabel,
    required this.rightLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: isDark ? Colors.white12 : AppColors.brandTint,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Both labels are flexible so a long one ellipsises rather than
            // wrapping and overflowing a narrow card.
            Expanded(
              child: Text(
                leftLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : AppColors.textMuted,
                ),
              ),
            ),
            if (rightLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  rightLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
