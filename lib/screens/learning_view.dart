import 'package:flutter/material.dart';

import '../models/learning_article.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_kit.dart';

/// Learning tab content. Deliberately has no Scaffold or AppBar because the
/// app shell already provides both.
class LearningView extends StatefulWidget {
  const LearningView({super.key});

  @override
  State<LearningView> createState() => _LearningViewState();
}

class _LearningViewState extends State<LearningView> {
  late Future<List<LearningArticle>> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService.instance.loadArticles();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<LearningArticle>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          );
        }
        final articles = snap.data ?? AdminService.fallbackArticles;

        if (articles.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_rounded,
            title: 'No lessons yet',
            subtitle: 'Your admin has not published any lessons so far.',
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
            const Text(
              'Financial Education',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Short, practical lessons to help you manage money',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpace.section),
            ...articles.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.gap),
                child: _LearnCard(article: a),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LearnCard extends StatelessWidget {
  final LearningArticle article;
  const _LearnCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LearningDetailView(article: article)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : AppColors.brandTint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.brand,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  article.summary,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? Colors.white60 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    );
  }
}

/// Pushed as its own route, so it keeps a Scaffold and AppBar.
class LearningDetailView extends StatelessWidget {
  final LearningArticle article;
  const LearningDetailView({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SurfaceCard(
              color: isDark ? Colors.white10 : AppColors.brandTint,
              child: Text(
                article.summary,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.brandDark,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              article.body,
              style: const TextStyle(fontSize: 15.5, height: 1.65),
            ),
          ],
        ),
      ),
    );
  }
}
