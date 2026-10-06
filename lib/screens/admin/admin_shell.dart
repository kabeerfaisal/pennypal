import 'package:flutter/material.dart';

import '../../controllers/finance_controller.dart';
import '../../models/app_user.dart';
import '../../services/admin_service.dart';
import '../../services/feedback_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/session.dart';
import '../../widgets/ui_kit.dart';
import 'admin_analytics.dart';
import 'admin_feedback.dart';
import 'admin_learning.dart';
import 'admin_users.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    AdminHome(),
    AdminUsersPage(),
    AdminAnalyticsPage(),
    AdminLearningPage(),
    AdminFeedbackPage(),
  ];

  static const List<String> _titles = [
    'Overview',
    'Users',
    'Analytics',
    'Learning',
    'Feedback',
  ];

  static const List<Widget> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.grid_view_rounded),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'Overview',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline_rounded),
      selectedIcon: Icon(Icons.people_rounded),
      label: 'Users',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights_rounded),
      label: 'Analytics',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'Learn',
    ),
    NavigationDestination(
      icon: Icon(Icons.feedback_outlined),
      selectedIcon: Icon(Icons.feedback_rounded),
      label: 'Support',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, size: 20),
            const SizedBox(width: 8),
            Text(_titles[_index]),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => logoutAndGoToLogin(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white12
                  : AppColors.border,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _destinations,
        ),
      ),
    );
  }
}

/// Admin overview. Every number is read live from Firestore.
class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final adminName = FinanceController.instance.userName;

    return StreamBuilder<List<AppUser>>(
      stream: AdminService.instance.watchUsers(),
      builder: (context, usersSnap) {
        final users = usersSnap.data ?? [];
        final students = users.where((u) => !u.isAdmin).length;
        final admins = users.length - students;

        return StreamBuilder<List<FeedbackItem>>(
          stream: FeedbackService.instance.watchAll(),
          builder: (context, fbSnap) {
            final feedback = fbSnap.data ?? [];
            final open = feedback.where((f) => f.status == 'Open').length;

            return StreamBuilder(
              stream: AdminService.instance.watchArticles(),
              builder: (context, artSnap) {
                final articles = artSnap.data ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.gutter,
                    AppSpace.gutter,
                    28,
                  ),
                  children: [
                    Text(
                      adminName.isEmpty ? 'Admin panel' : 'Hi, $adminName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Live numbers pulled straight from Firestore.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpace.section),

                    _row([
                      StatCard(
                        label: 'Total Users',
                        value: '${users.length}',
                        icon: Icons.people_rounded,
                        color: AppColors.info,
                      ),
                      StatCard(
                        label: 'Students',
                        value: '$students',
                        icon: Icons.person_rounded,
                        color: AppColors.brand,
                      ),
                      StatCard(
                        label: 'Admins',
                        value: '$admins',
                        icon: Icons.shield_rounded,
                        color: Colors.indigo,
                      ),
                    ]),
                    const SizedBox(height: AppSpace.gap),
                    _row([
                      StatCard(
                        label: 'Open Queries',
                        value: '$open',
                        icon: Icons.support_agent_rounded,
                        color: open > 0
                            ? AppColors.warning
                            : AppColors.textMuted,
                      ),
                      StatCard(
                        label: 'Total Feedback',
                        value: '${feedback.length}',
                        icon: Icons.feedback_rounded,
                        color: AppColors.info,
                      ),
                      StatCard(
                        label: 'Articles',
                        value: '${articles.length}',
                        icon: Icons.menu_book_rounded,
                        color: AppColors.brand,
                      ),
                    ]),

                    const SizedBox(height: AppSpace.section),
                    const SectionHeader(title: 'Recent activity'),
                    _RecentActivity(
                      users: users,
                      feedback: feedback,
                      articles: articles,
                    ),

                    const SizedBox(height: AppSpace.section),
                    SurfaceCard(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.tint(AppColors.brand),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.brand,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Manage students in the Users tab: change a role, '
                              'or suspend an account.',
                              style: TextStyle(fontSize: 13, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _row(List<Widget> children) => Row(
    children: children
        .map(
          (c) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpace.gap),
              child: c,
            ),
          ),
        )
        .toList(),
  );
}

class _RecentActivity extends StatelessWidget {
  final List<AppUser> users;
  final List<FeedbackItem> feedback;
  final List<dynamic> articles;

  const _RecentActivity({
    required this.users,
    required this.feedback,
    required this.articles,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (feedback.isNotEmpty)
        _row(
          Icons.support_agent_rounded,
          AppColors.warning,
          feedback.first,
          '${feedback.first.userName.isEmpty ? feedback.first.userEmail : feedback.first.userName} sent a ${feedback.first.type.toLowerCase()}',
        ),
      if (users.isNotEmpty)
        _row(
          Icons.person_add_alt_rounded,
          AppColors.brand,
          users.first,
          '${users.first.fullName.isEmpty ? users.first.email : users.first.fullName} is on the platform',
        ),
      if (articles.isNotEmpty)
        _row(
          Icons.menu_book_rounded,
          AppColors.info,
          articles.first,
          'Latest article: ${articles.first.title}',
        ),
    ];

    if (rows.isEmpty) {
      return const SurfaceCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'No activity yet',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: rows),
    );
  }

  Widget _row(IconData icon, Color color, dynamic item, String text) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.tint(color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
      title: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13.5, height: 1.35),
      ),
    );
  }
}
