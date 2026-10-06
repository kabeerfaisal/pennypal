import 'package:flutter/material.dart';

import '../widgets/developers_section.dart';
import '../widgets/pennypal_logo.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About PennyPal')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PennyPalLogo(
            size: 88,
            background: cs.primary.withValues(alpha: 0.14),
            foreground: cs.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'PennyPal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Smart budgeting for students',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _card(
            'Our goal',
            'Help students see where money goes, stay inside a monthly plan, '
                'and save for real targets like a laptop, trip, or study materials — without complicated banking tools.',
          ),
          _card(
            'What you can do',
            '• Track income and expenses by category\n'
                '• Set a monthly budget and per-category spending limits\n'
                '• Block extra spend when a category limit is hit\n'
                '• Build savings goals with dates, contributions, and milestones\n'
                '• Download an Excel spending report\n'
                '• Ask the in-app advisor using your real numbers\n'
                '• Send feedback or a query to the admin team',
          ),
          _card(
            'How it stays useful',
            'Data lives in your Firebase account so totals, goals, and limits stay in sync. '
                'Budget and savings alerts appear both in the app and as notifications on your phone, '
                'without any remote push service. '
                'Receipt photos are compressed and saved with the transaction. '
                'Light and dark themes keep the same layout.',
          ),
          _card(
            'Roles',
            'Students use the main app for money tracking. Admins get a separate panel to manage users, learning lessons, and student feedback.',
          ),
          const SizedBox(height: 8),
          const Divider(),
          // Privacy has to be reachable before sign in as well, not only from
          // inside the app, so it is a real button rather than a line of text.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
              icon: const Icon(Icons.privacy_tip_outlined, size: 18),
              label: const Text('Read our Privacy Policy'),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          DevelopersSection(accent: cs.primary),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© ${DateTime.now().year} PennyPal',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, String body) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(height: 1.45)),
          ],
        ),
      ),
    );
  }
}
