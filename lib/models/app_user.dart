import '../utils/parse.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String currency;
  final String theme;
  final double monthlyBudget;

  /// Set by an admin. A suspended student sees a blocked screen on sign in.
  final bool isSuspended;
  final String suspendedReason;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.currency,
    required this.theme,
    required this.monthlyBudget,
    this.isSuspended = false,
    this.suspendedReason = '',
  });

  bool get isAdmin => UserRole.isAdmin(role);

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      fullName: data['FullName'] ?? data['fullName'] ?? '',
      email: data['Email'] ?? data['email'] ?? '',
      phone: data['Phone'] ?? data['phone'] ?? '',
      role: UserRole.fromData(data),
      currency: data['Currency'] ?? data['currency'] ?? 'USD',
      theme: data['Theme'] ?? data['theme'] ?? 'Green',
      monthlyBudget: asMoney(
        data['MonthlyBudget'] ?? data['monthlyBudget'],
        2000,
      ),
      isSuspended: data['IsSuspended'] == true,
      suspendedReason: data['SuspendedReason'] ?? '',
    );
  }
}
