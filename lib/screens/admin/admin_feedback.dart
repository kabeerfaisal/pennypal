import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/feedback_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

class AdminFeedbackPage extends StatelessWidget {
  const AdminFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedbackItem>>(
      stream: FeedbackService.instance.watchAll(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load feedback',
            subtitle: 'Check that firestore.rules is deployed.',
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_rounded,
            title: 'No student feedback yet',
            subtitle: 'Queries and feedback from students land here.',
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
            ResultStrip(
              count: items.length,
              totalLabel: 'Open',
              totalValue: '${items.where((f) => f.status == 'Open').length}',
            ),
            for (final f in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.gap),
                child: _Card(item: f),
              ),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final FeedbackItem item;
  const _Card({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answered = item.isAnswered;

    return SurfaceCard(
      onTap: () => _openSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tint(
                    answered ? AppColors.income : AppColors.warning,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: answered ? AppColors.income : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.type,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (item.rating > 0) ...[
                Icon(Icons.star_rounded, size: 15, color: AppColors.accent),
                Text(
                  '${item.rating}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                DateFormat('d MMM').format(item.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.userName.isEmpty ? item.userEmail : item.userName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (item.subject.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.subject,
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white60 : AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            item.message,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
          if (item.hasResponse) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.brand),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: const Border(
                  left: BorderSide(color: AppColors.brand, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your reply',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.adminResponse,
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (!answered)
                TextButton.icon(
                  onPressed: () => _openSheet(context),
                  icon: const Icon(Icons.reply_rounded, size: 18),
                  label: const Text('Reply'),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => FeedbackService.instance.setStatus(
                  item.id,
                  item.status == 'Open' ? 'Resolved' : 'Open',
                ),
                icon: Icon(
                  item.status == 'Open'
                      ? Icons.check_circle_outline_rounded
                      : Icons.refresh_rounded,
                  size: 18,
                ),
                label: Text(item.status == 'Open' ? 'Mark resolved' : 'Reopen'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final ctrl = TextEditingController(text: item.adminResponse);
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reply to student',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                item.userName.isEmpty ? item.userEmail : item.userName,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? Colors.white60
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? Colors.white10
                      : AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  item.message,
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Your response',
                  alignLabelWithHint: true,
                  hintText: 'Type the answer the student will see...',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        if (ctrl.text.trim().isEmpty) return;
                        await FeedbackService.instance.reply(
                          item.id,
                          ctrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Reply sent to student'),
                          ),
                        );
                      },
                      child: const Text('Send reply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
