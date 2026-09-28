import 'package:flutter/material.dart';

import '../controllers/finance_controller.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

/// SRS `UserProfiles` entity editor: student status, profile image and the
/// in-app alert preference.
///
/// Reads and writes through [FinanceController] so the header avatar and this
/// section never disagree.
class UserProfilesSection extends StatefulWidget {
  final FinanceController controller;
  const UserProfilesSection({super.key, required this.controller});

  @override
  State<UserProfilesSection> createState() => _UserProfilesSectionState();
}

class _UserProfilesSectionState extends State<UserProfilesSection> {
  late String _status = widget.controller.studentStatus;
  late String _avatar = widget.controller.profileAvatar;
  late bool _alerts = widget.controller.alertsEnabled;

  Future<void> _save() {
    return widget.controller.saveProfile(
      studentStatus: _status,
      avatarEmoji: _avatar,
      alertsEnabled: _alerts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white60 : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadow.soft(Theme.of(context).colorScheme),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Student profile',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: UserProfile.statusOptions.contains(_status)
                ? _status
                : UserProfile.statusOptions.first,
            decoration: const InputDecoration(
              labelText: 'Student status',
              isDense: true,
            ),
            items: UserProfile.statusOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _status = v);
              _save();
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Profile image',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : AppColors.brandTint,
                  shape: BoxShape.circle,
                ),
                child: Text(_avatar, style: const TextStyle(fontSize: 24)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserProfile.avatarOptions.map((e) {
              final selected = e == _avatar;
              return GestureDetector(
                onTap: () {
                  setState(() => _avatar = e);
                  _save();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brandTint
                        : (isDark ? Colors.white10 : AppColors.canvas),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.brand : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _alerts,
            onChanged: (v) {
              setState(() => _alerts = v);
              _save();
            },
            title: const Text('In-app alerts', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              'Spending limits and goal milestones',
              style: TextStyle(fontSize: 11.5, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
