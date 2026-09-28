import 'package:flutter/material.dart';

import '../../models/learning_article.dart';
import '../../services/admin_service.dart';

class AdminLearningPage extends StatelessWidget {
  const AdminLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        StreamBuilder<List<LearningArticle>>(
          stream: AdminService.instance.watchArticles(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Could not load articles. Check Firestore rules.',
                  ),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: cs.primary),
              );
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return const Center(
                child: Text('No articles yet. Add the first lesson.'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final a = items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      a.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      a.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          AdminService.instance.deleteArticle(a.id),
                    ),
                    onTap: () => _edit(context, a),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Article'),
            onPressed: () => _edit(context, null),
          ),
        ),
      ],
    );
  }

  void _edit(BuildContext context, LearningArticle? existing) {
    final title = TextEditingController(text: existing?.title ?? '');
    final summary = TextEditingController(text: existing?.summary ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    final order = TextEditingController(text: '${existing?.order ?? 0}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing == null ? 'New article' : 'Edit article',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: summary,
                  decoration: const InputDecoration(
                    labelText: 'Summary',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: body,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: order,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Order',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(),
                    onPressed: () async {
                      if (title.text.trim().isEmpty) return;
                      await AdminService.instance.saveArticle(
                        LearningArticle(
                          id: existing?.id ?? '',
                          title: title.text.trim(),
                          summary: summary.text.trim(),
                          body: body.text.trim(),
                          order: int.tryParse(order.text) ?? 0,
                        ),
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
