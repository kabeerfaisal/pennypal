import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

/// Reads and writes the SRS `UserProfiles` document for the signed in student.
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final _db = FirebaseFirestore.instance;

  Future<UserProfile?> load(String userId) async {
    try {
      final doc = await _db
          .collection('Users')
          .doc(userId)
          .collection('Profile')
          .doc('me')
          .get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc.data() ?? {}, userId);
    } catch (_) {
      // A missing or blocked profile must not break the app.
      return null;
    }
  }

  /// Creates the profile on first write, then merges on later writes.
  Future<void> save(UserProfile profile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? profile.userId;
    await _db
        .collection('Users')
        .doc(uid)
        .collection('Profile')
        .doc('me')
        .set(
          profile.copyWith().toMap()..['UserId'] = uid,
          SetOptions(merge: true),
        );
  }
}
