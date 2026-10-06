import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/finance_controller.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/phone_rule.dart';
import '../utils/session.dart';
import 'profile_preferences.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: FinanceController.instance,
      builder: (context, _) {
        final c = FinanceController.instance;
        return Scaffold(
          appBar: AppBar(title: const Text('Profile & Settings')),
          body: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              // Header. The top padding is what stops the avatar looking cut off
              // against the app bar, and the bottom radius keeps the green from
              // running flat into the white list below.
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  // Leaves room for the status bar when this screen is the one
                  // with no app bar of its own.
                  20,
                  20,
                  24,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: c.profileAvatar.isNotEmpty
                          ? Text(
                              c.profileAvatar,
                              style: const TextStyle(fontSize: 40),
                            )
                          : Text(
                              c.userName.isNotEmpty
                                  ? c.userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.userEmail,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (c.userPhone.isNotEmpty)
                      Text(
                        '📞 ${c.userPhone}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c.userRole,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Settings Section
              const SizedBox(height: 12),
              _sectionHeader('Preferences'),
              UserProfilesSection(controller: c),
              const SizedBox(height: 8),
              _settingTile(
                icon: Icons.currency_exchange,
                title: 'Currency',
                trailing: DropdownButton<String>(
                  value: c.currency,
                  underline: const SizedBox(),
                  items: ['USD', 'PKR', 'INR', 'EURO']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) c.setCurrency(val);
                  },
                ),
              ),

              const SizedBox(height: 8),
              _sectionHeader('Appearance'),
              // RadioGroup owns the selection for both tiles. The old
              // groupValue/onChanged pair on each Radio is deprecated and will
              // be removed, which would leave two independent radios.
              RadioGroup<String>(
                groupValue: c.isDarkTheme ? 'Dark' : 'Light',
                onChanged: (v) {
                  if (v != null) c.setTheme(v);
                },
                child: Column(
                  children: [
                    _settingTile(
                      icon: Icons.light_mode_outlined,
                      title: 'Light Theme',
                      subtitle: 'Clean white, green accents',
                      // The whole row switches, not just the small radio.
                      onTap: () => c.setTheme('Light'),
                      trailing: Radio<String>(
                        value: 'Light',
                        activeColor: AppColors.brand,
                      ),
                    ),
                    _settingTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Theme',
                      subtitle: 'True black, easy on the eyes',
                      onTap: () => c.setTheme('Dark'),
                      trailing: const Radio<String>(value: 'Dark'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              _sectionHeader('Account'),
              _settingTile(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                subtitle: 'Name and phone',
                onTap: () => _showEditProfile(context, c),
              ),
              Builder(
                builder: (ctx) {
                  return _settingTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: ctx,
                        builder: (d) => AlertDialog(
                          scrollable: true,
                          title: const Text('Logout?'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(d, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(d, true),
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && ctx.mounted) {
                        await logoutAndGoToLogin(ctx);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 6),
              _settingTile(
                icon: Icons.delete_forever_outlined,
                title: 'Delete my account',
                subtitle: 'Removes everything and releases your email',
                iconColor: AppColors.expense,
                titleColor: AppColors.expense,
                onTap: () => _confirmDeleteAccount(context),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  /// Self-service account deletion, the only deletion in the app that actually
  /// completes.
  ///
  /// Firebase gives clients no way to remove *somebody else's* sign-in, so the
  /// admin panel cannot delete a student. A student can delete themselves, and
  /// this is the path: re-authenticate, delete the Auth record so the email is
  /// released, then clear the data.
  ///
  /// Typed in a State rather than holding a controller across the dialog,
  /// because disposing a caller-owned controller while the route is still
  /// animating away threw.
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeleteAccountDialog(),
    );
    if (password == null || password.isEmpty || !context.mounted) {
      if (password != null && password.isEmpty && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Enter your password to confirm')),
        );
      }
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Deleting your account...')),
    );

    final problem = await AuthService().deleteCurrentAccount(
      password: password,
    );

    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }

    // The account is gone, so tear the local session down and go back to the
    // start rather than leaving a half signed in shell on screen.
    FinanceController.instance.clearData();
    if (!navigator.mounted) return;
    navigator.popUntil((route) => route.isFirst);
    if (!navigator.mounted) return;
    await logoutAndGoToLogin(navigator.context);
  }

  void _showEditProfile(BuildContext context, FinanceController c) {
    final name = TextEditingController(text: c.userName);
    final phone = TextEditingController(
      text: c.userPhone.replaceAll(RegExp(r'\D'), ''),
    );
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          // Two fields plus a helper line do not fit on a short screen at a
          // large system font, which pushed the Save button out of view.
          scrollable: true,
          title: const Text('Edit profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                // A plain number keypad, not TextInputType.phone. The phone
                // type makes Chrome and Android offer their autofill service,
                // which drops a list of every contact and number saved on the
                // device over the field. The field only ever holds digits
                // anyway, because the country code is kept separately.
                keyboardType: TextInputType.number,
                inputFormatters: [
                  // Digits only, so letters and punctuation can never be saved
                  // into the phone field.
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(PhoneRule.max),
                ],
                // Belt and braces for the same autofill dropdown. An empty
                // hint list tells the platform this is not an autofill target.
                autofillHints: const <String>[],
                enableSuggestions: false,
                autocorrect: false,
                enableIMEPersonalizedLearning: false,
                onChanged: (_) {
                  if (error != null) setD(() => error = null);
                },
                decoration: InputDecoration(
                  labelText: 'Phone',
                  helperText: PhoneRule.hint,
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final digits = phone.text.trim();
                final problem = PhoneRule.validate(digits);
                if (problem != null) {
                  setD(() => error = problem);
                  return;
                }
                if (name.text.trim().isEmpty) {
                  setD(() => error = 'Name cannot be empty');
                  return;
                }
                final messenger = ScaffoldMessenger.of(ctx);
                final country = _dialFor(c.userPhone);
                Navigator.pop(ctx);
                await c.updateProfile(
                  name: name.text.trim(),
                  phone: '$country$digits',
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Keeps the stored country code, so editing the number does not silently
  /// drop the +92 prefix the student registered with.
  static String _dialFor(String stored) {
    final m = RegExp(r'^(\+\d{1,4})').firstMatch(stored.trim());
    return m == null ? '' : m.group(1)!;
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: titleColor),
        ),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing:
            trailing ??
            (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }
}

/// Asks for the password, then returns it so the caller can do the delete.
///
/// A State rather than a builder closure, because the controller has to be
/// disposed with the widget. Disposing a controller that the caller still owns,
/// while the dialog route is animating away, threw on the way out.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm');
      return;
    }
    Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // The warning plus a text field do not fit on a short screen at a large
      // system font, which pushed the buttons out of view.
      scrollable: true,
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_forever_rounded,
          color: AppColors.expense,
          size: 28,
        ),
      ),
      title: const Text('Delete your account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Everything goes: your transactions, savings goals, profile, '
            'notifications, AI chats and any messages you sent. Your email '
            'is released so it can be registered again.\n\nThis cannot be '
            'undone.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Confirm with your password',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
          onPressed: _submit,
          child: const Text('Delete everything'),
        ),
      ],
    );
  }
}
