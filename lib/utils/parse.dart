class UserRole {
  static String fromData(Map<String, dynamic>? data) {
    if (data == null) return 'Student';

    final flag = data['IsAdmin'] ?? data['isAdmin'] ?? data['admin'];
    if (flag == true || flag == 1 || '$flag'.toLowerCase() == 'true') {
      return 'Admin';
    }

    final raw = (data['Role'] ?? data['role'] ?? data['userRole'] ?? '')
        .toString()
        .trim();
    if (raw.toLowerCase() == 'admin') return 'Admin';
    if (raw.isEmpty) return 'Student';
    return raw;
  }

  static bool isAdmin(String role) => role.trim().toLowerCase() == 'admin';
}

double asMoney(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

int asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
