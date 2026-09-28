import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/transaction_model.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/success_overlay.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<List<AppUser>>(
      stream: AdminService.instance.watchUsers(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }
        final filtered = snap.data!.where((u) {
          final q = _query.toLowerCase();
          if (q.isEmpty) return true;
          return u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search name or email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final user = filtered[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primary.withValues(alpha: 0.15),
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        user.fullName.isEmpty ? 'No name' : user.fullName,
                      ),
                      subtitle: Text('${user.email}\n${user.role}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUserDetail(user: user),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class AdminUserDetail extends StatelessWidget {
  final AppUser user;
  const AdminUserDetail({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // The passed-in user is a snapshot from the list, so it goes stale the
    // moment anything changes. Re-reading the document here means the Suspend
    // button flips to "Restore access" on its own, with no manual reload.
    return StreamBuilder<AppUser?>(
      stream: AdminService.instance.watchUser(user.id),
      builder: (context, snap) {
        final live = snap.data ?? user;
        return Scaffold(
          appBar: AppBar(
            title: Text(live.fullName.isEmpty ? live.email : live.fullName),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _userCard(context, live),
              const SizedBox(height: 16),
              const Text(
                'Recent transactions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _transactions(user.id),
            ],
          ),
        );
      },
    );
  }

  /// True when the row is the signed-in admin's own account. Every destructive
  /// action is disabled in that case, because locking yourself out cannot be
  /// undone from inside the app.
  bool _isSelf(AppUser u) => u.id == AdminService.myUid;

  Widget _userCard(BuildContext context, AppUser user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final self = _isSelf(user);
    final label = user.fullName.isEmpty ? user.email : user.fullName;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white54 : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.isSuspended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      'Suspended',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.expense,
                      ),
                    ),
                  ),
              ],
            ),
            if (user.phone.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(user.phone),
            ],
            const SizedBox(height: 8),
            Text('Currency: ${user.currency}'),
            Text('Budget: ${user.monthlyBudget.toStringAsFixed(0)}'),
            if (user.isSuspended) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: AppColors.expense, width: 3),
                  ),
                ),
                child: Text(
                  user.suspendedReason.isEmpty
                      ? 'Account suspended'
                      : user.suspendedReason,
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Role'),
                const Spacer(),
                DropdownButton<String>(
                  value: user.isAdmin ? 'Admin' : 'Student',
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  ],
                  onChanged: self
                      ? null
                      : (v) async {
                          if (v == null) return;
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await AdminService.instance.setRole(user.id, v);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Role set to $v')),
                            );
                          } on AdminActionException catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          }
                        },
                ),
              ],
            ),
            if (self) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: isDark ? Colors.white54 : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This is your own account. Suspend, delete and role '
                      'changes are disabled.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark ? Colors.white54 : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: self
                        ? null
                        : () => _toggleSuspend(context, user),
                    icon: Icon(
                      user.isSuspended
                          ? Icons.lock_open_rounded
                          : Icons.block_rounded,
                      size: 18,
                    ),
                    label: Text(
                      user.isSuspended ? 'Restore access' : 'Suspend',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: self
                        ? null
                        : () => _confirmDelete(context, user),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      disabledBackgroundColor: isDark
                          ? AppColors.black3
                          : AppColors.border,
                      disabledForegroundColor: isDark
                          ? Colors.white38
                          : AppColors.textMuted,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _transactions(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Transactions')
          .orderBy('Date', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No transactions yet'),
          );
        }
        return Column(
          children: snap.data!.docs.map((d) {
            final tx = TransactionModel.fromFirestore(d.data(), d.id);
            return ListTile(
              title: Text(tx.title),
              subtitle: Text(tx.category),
              trailing: Text(
                '${tx.isExpense ? '-' : '+'}${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tx.isExpense ? AppColors.expense : AppColors.income,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// A proper confirmation dialog with a reason field, then a success screen.
  Future<void> _toggleSuspend(BuildContext context, AppUser user) async {
    final restoring = user.isSuspended;
    final label = user.fullName.isEmpty ? user.email : user.fullName;
    final messenger = ScaffoldMessenger.of(context);

    if (restoring) {
      final ok = await ConfirmDialog.show(
        context,
        title: 'Restore access?',
        message: '$label will be able to use PennyPal again straight away.',
        confirmLabel: 'Restore access',
        color: AppColors.income,
        icon: Icons.lock_open_rounded,
      );
      if (!ok || !context.mounted) return;
      try {
        await AdminService.instance.setSuspended(user.id, false);
        if (!context.mounted) return;
        await SuccessOverlay.show(
          context,
          title: 'Access restored',
          subtitle: '$label can use the app again.',
          detail: 'Restored',
          actionLabel: 'Done',
          icon: Icons.lock_open_rounded,
          color: AppColors.income,
        );
      } on AdminActionException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not restore: $e')),
        );
      }
      return;
    }

    final reasonCtrl = TextEditingController(
      text: 'Repeated policy violations',
    );
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Suspend this account?',
      message:
          '$label will be signed out and shown a blocked screen. Their data '
          'is kept, and they can appeal from that screen.',
      confirmLabel: 'Suspend',
      color: AppColors.expense,
      icon: Icons.block_rounded,
      field: TextField(
        controller: reasonCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Reason (shown to the user)',
          alignLabelWithHint: true,
        ),
      ),
    );

    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (!confirmed || !context.mounted) return;

    try {
      await AdminService.instance.setSuspended(user.id, true, reason: reason);
      if (!context.mounted) return;
      await SuccessOverlay.show(
        context,
        title: 'Account suspended',
        subtitle: '$label is now blocked from using PennyPal.',
        detail: reason.isEmpty ? 'No reason given' : reason,
        actionLabel: 'Done',
        icon: Icons.block_rounded,
        color: AppColors.expense,
      );
    } on AdminActionException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not suspend: $e')));
    }
  }

  /// Deleting is permanent, so it is confirmed rather than a single tap.
  Future<void> _confirmDelete(BuildContext context, AppUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    final label = user.fullName.isEmpty ? user.email : user.fullName;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete this account?',
      message:
          '$label will be signed out and their transactions, goals and '
          'profile will be permanently removed. This cannot be undone.',
      confirmLabel: 'Delete permanently',
      color: AppColors.expense,
      icon: Icons.delete_forever_rounded,
    );
    if (!confirmed || !context.mounted) return;

    messenger.showSnackBar(const SnackBar(content: Text('Deleting...')));
    try {
      await AdminService.instance.deleteUser(user.id);
      messenger.showSnackBar(SnackBar(content: Text('$label deleted')));
      if (context.mounted) Navigator.pop(context);
    } on AdminActionException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }
}
