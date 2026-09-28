import 'package:cloud_firestore/cloud_firestore.dart';

/// SRS database design `UserProfiles` entity:
/// ProfileId(PK), UserId(FK), StudentStatus, CurrencyPreference,
/// NotificationPreference, ProfileImage.
class UserProfile {
  final String userId;
  final String studentStatus;
  final String currency;
  final bool notificationsEnabled;

  /// Stored as an emoji or a short label rather than a binary image, because
  /// Cloud Storage is not enabled for this project.
  final String avatarEmoji;

  const UserProfile({
    required this.userId,
    this.studentStatus = 'Undergraduate',
    this.currency = 'USD',
    this.notificationsEnabled = true,
    this.avatarEmoji = '🙂',
  });

  static const List<String> statusOptions = [
    'School student',
    'Undergraduate',
    'Postgraduate',
    'Working',
    'Other',
  ];

  static const List<String> avatarOptions = [
    '🙂',
    '😀',
    '🎓',
    '💼',
    '📚',
    '🚀',
    '🌱',
    '⭐',
    '🐼',
    '🦊',
  ];

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String userId) {
    return UserProfile(
      userId: userId,
      studentStatus: data['StudentStatus'] ?? 'Undergraduate',
      currency: data['CurrencyPreference'] ?? 'USD',
      notificationsEnabled: data['NotificationPreference'] != false,
      avatarEmoji: data['ProfileImage'] ?? '🙂',
    );
  }

  Map<String, dynamic> toMap() => {
    'UserId': userId,
    'StudentStatus': studentStatus,
    'CurrencyPreference': currency,
    'NotificationPreference': notificationsEnabled,
    'ProfileImage': avatarEmoji,
    'UpdatedAt': FieldValue.serverTimestamp(),
  };

  UserProfile copyWith({
    String? studentStatus,
    String? currency,
    bool? notificationsEnabled,
    String? avatarEmoji,
  }) {
    return UserProfile(
      userId: userId,
      studentStatus: studentStatus ?? this.studentStatus,
      currency: currency ?? this.currency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }
}
