import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// SRS 1.6: "The Contact Support screen should allow students to submit
/// subject and message details", validate required fields, and confirm after a
/// successful submission.
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({
    super.key,
    this.initialTopic,
    this.initialSubject,
    this.initialMessage,
    this.title = 'Contact Support',
  });

  /// Lets another screen open this as a pre-filled appeal. The suspended
  /// screen uses it so a blocked user can still reach the admin.
  final String? initialTopic;
  final String? initialSubject;
  final String? initialMessage;
  final String title;

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  static const List<String> _topics = [
    'Account & login',
    'Budget problem',
    'Data issue',
    'Feature request',
    'Something else',
  ];

  late final TextEditingController _subjectCtrl = TextEditingController(
    text: widget.initialSubject ?? '',
  );
  late final TextEditingController _messageCtrl = TextEditingController(
    text: widget.initialMessage ?? '',
  );
  late String _topic = _topics.contains(widget.initialTopic)
      ? widget.initialTopic!
      : _topics.first;
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a subject and a message first.')),
      );
      return;
    }

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FeedbackService.instance.submit(
        type: widget.initialTopic == null ? 'Query' : 'Appeal',
        message: message,
        subject: '[$_topic] $subject',
      );
      if (!mounted) return;
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() => _sending = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Query sent. The admin team will reply here.'),
        ),
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
      appBar: AppBar(title: Text(widget.title)),
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
                  'Raise a query',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tell us what went wrong and the admin team will respond.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _topic,
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _topics
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _topic = v ?? _topic),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageCtrl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    hintText: 'Describe the problem in detail...',
                  ),
                ),
                const SizedBox(height: 16),
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
                    label: Text(_sending ? 'Sending...' : 'Submit query'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.section),
          const SectionHeader(title: 'Your queries'),
          _queryList(),
        ],
      ),
    );
  }

  /// Kept separate so a Firestore failure degrades to a message instead of
  /// taking down the whole screen. The form above stays usable, which matters
  /// most for a suspended user who has no other way to reach the admin.
  Widget _queryList() {
    Stream<List<FeedbackItem>> stream;
    try {
      stream = FeedbackService.instance.watchMine();
    } catch (e) {
      debugPrint('Could not open the query list: $e');
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Cannot load your queries',
        subtitle:
            'Check your connection. Sending a new query above still '
            'works once the app is online.',
      );
    }

    return StreamBuilder<List<FeedbackItem>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Cannot load your queries',
            subtitle: 'Check your connection and pull to refresh.',
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = (snap.data ?? [])
            .where((f) => f.type == 'Query' || f.type == 'Appeal')
            .toList();
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.support_agent_rounded,
            title: 'No queries yet',
            subtitle: 'Anything you send here appears with the admin reply.',
          );
        }
        return Column(
          children: [
            for (final f in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.gap),
                child: SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              f.subject.isEmpty ? 'Query' : f.subject,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('d MMM').format(f.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white54
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f.message,
                        style: const TextStyle(fontSize: 13, height: 1.45),
                      ),
                      if (f.hasResponse) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.tint(AppColors.brand),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            border: const Border(
                              left: BorderSide(
                                color: AppColors.brand,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Admin reply',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandDark,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                f.adminResponse,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
