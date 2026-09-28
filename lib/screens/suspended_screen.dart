import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/session.dart';
import 'contact_support_screen.dart';

/// Shown instead of the app when an admin has suspended the account.
class SuspendedScreen extends StatelessWidget {
  final String name;
  final String reason;

  const SuspendedScreen({super.key, this.name = '', this.reason = ''});

  /// Opens the support form pre-filled as an appeal, so a blocked user can
  /// still ask the admin to restore access. The account is still authenticated
  /// here, so writing to `Feedbacks` is permitted by the Firestore rules.
  void _appeal(BuildContext context) {
    final who = name.trim().isEmpty ? 'My account' : 'My account ($name)';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContactSupportScreen(
          title: 'Appeal Suspension',
          initialTopic: 'Account & login',
          initialSubject: 'Request to restore access',
          initialMessage:
              'Hello admin, $who has been suspended'
              '${reason.trim().isEmpty ? '' : ' for this reason: "$reason".'}'
              '\n\nI believe this is a mistake. Please review and restore my '
              'access.\n\nReason: ',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    color: AppColors.tint(AppColors.expense),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    size: 52,
                    color: AppColors.expense,
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'You are suspended',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name.isEmpty
                      ? 'Your account has been paused by an administrator.'
                      : '$name, your account has been paused by an administrator.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14.5, height: 1.5),
                ),
                if (reason.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.tint(AppColors.expense),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: const Border(
                        left: BorderSide(color: AppColors.expense, width: 3),
                      ),
                    ),
                    child: Text(
                      reason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13.5, height: 1.5),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  'Your data is safe and will be here once your account is '
                  'restored. Contact the admin team if you think this is a mistake.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                // A blocked user still needs a way to reach the admin, so the
                // appeal form is offered here and pre-filled with the topic.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _appeal(context),
                    icon: const Icon(Icons.support_agent_rounded, size: 19),
                    label: const Text('Contact admin'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.refresh_rounded, size: 19),
                    label: const Text('Check again'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => logoutAndGoToLogin(context),
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
