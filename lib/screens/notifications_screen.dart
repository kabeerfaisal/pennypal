import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// The notification centre, reachable from the bell in the app bar.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          ListenableBuilder(
            listenable: NotificationService.instance,
            builder: (context, _) {
              if (NotificationService.instance.unreadCount == 0) {
                return const SizedBox(width: 8);
              }
              return TextButton(
                onPressed: NotificationService.instance.markAllRead,
                child: const Text('Mark all read'),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: NotificationService.instance,
        builder: (context, _) {
          final s = NotificationService.instance;
          final items = s.items;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle:
                  'You will be told here when a transaction is added, a budget '
                  'limit is hit, or a savings goal reaches a milestone.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.gutter,
              AppSpace.gutter,
              28,
            ),
            children: [
              if (s.unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${s.unreadCount} unread',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              for (final n in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.gap),
                  child: _NotificationRow(entry: n),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification entry;

  const _NotificationRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final look = _lookFor(entry.kind, isDark);
    final ago = _relative(entry.at);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => NotificationService.instance.remove(entry.id),
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        // The unread dot is the tap affordance, so the whole row marks read.
        onTap: () => NotificationService.instance.markRead(entry.id),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: look.bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(look.icon, size: 20, color: look.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: entry.read
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ago,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.body,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? Colors.white60 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!entry.read) ...[
              const SizedBox(width: 8),
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static _Look _lookFor(NotifyKind kind, bool isDark) {
    Color base;
    IconData icon;
    switch (kind) {
      case NotifyKind.transaction:
        base = AppColors.info;
        icon = Icons.receipt_long_rounded;
      case NotifyKind.budget:
        base = AppColors.expense;
        icon = Icons.donut_large_rounded;
      case NotifyKind.goal:
        base = AppColors.income;
        icon = Icons.savings_rounded;
      case NotifyKind.limit:
        base = AppColors.warning;
        icon = Icons.speed_rounded;
      case NotifyKind.admin:
        base = const Color(0xFF7C3AED);
        icon = Icons.shield_rounded;
      case NotifyKind.feedback:
        base = AppColors.accent;
        icon = Icons.support_agent_rounded;
      case NotifyKind.system:
        base = AppColors.info;
        icon = Icons.info_rounded;
    }
    return _Look(
      bg: isDark ? base.withValues(alpha: 0.22) : base.withValues(alpha: 0.12),
      fg: isDark ? Colors.white : base,
      icon: icon,
    );
  }

  /// Compact age label, e.g. "2m", "3h", "12 Mar".
  static String _relative(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM').format(at);
  }
}

class _Look {
  final Color bg;
  final Color fg;
  final IconData icon;
  const _Look({required this.bg, required this.fg, required this.icon});
}
