import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _type = 'Feedback';
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _messageCtrl.text.trim();
    if (message.isEmpty || _sending) return;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FeedbackService.instance.submit(
        type: _type,
        message: message,
        subject: _subjectCtrl.text.trim(),
        rating: _rating,
      );
      if (!mounted) return;
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() {
        _rating = 0;
        _sending = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Sent to admin. Thank you!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not send: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback & Queries')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.gutter,
          AppSpace.gutter,
          28,
        ),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a message',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Feedback', label: Text('Feedback')),
                    ButtonSegment(value: 'Query', label: Text('Query')),
                    ButtonSegment(value: 'Bug', label: Text('Bug')),
                  ],
                  selected: {_type},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject (optional)',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    hintText: 'Tell us what is on your mind...',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Rate your experience',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (i) {
                    final value = i + 1;
                    final filled = value <= _rating;
                    return IconButton(
                      onPressed: () => setState(
                        () => _rating = _rating == value ? 0 : value,
                      ),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled ? AppColors.accent : AppColors.border,
                        size: 30,
                      ),
                      tooltip: '$value star${value == 1 ? '' : 's'}',
                    );
                  }),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 19),
                    label: Text(_sending ? 'Sending...' : 'Submit'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.section),
          const Text(
            'Your submissions',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<FeedbackItem>>(
            stream: FeedbackService.instance.watchMine(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'Nothing sent yet',
                  subtitle: 'Your feedback and queries will appear here with admin replies.',
                );
              }
              return Column(
                children: [
                  for (final f in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.gap),
                      child: _MyItem(item: f),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MyItem extends StatelessWidget {
  final FeedbackItem item;
  const _MyItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answered = item.isAnswered;

    return SurfaceCard(
      borderless: true,
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
                  answered ? 'Answered' : item.status,
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
                const SizedBox(width: 8),
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
          if (item.subject.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.subject,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 4),
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
                  Row(
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        size: 16,
                        color: AppColors.brandDark,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Admin reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.adminResponse,
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
