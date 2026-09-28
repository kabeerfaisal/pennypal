import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A student feedback item or support query.
///
/// Covers the SRS `Feedbacks` entity plus the `AdminResponse` attribute the
/// specification lists on SupportQueries.
class FeedbackItem {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String type;
  final String subject;
  final String message;

  /// 1 to 5 stars. Zero when the student left no rating, which is legal for a
  /// support query.
  final int rating;

  final DateTime createdAt;
  final String status;
  final String adminResponse;
  final DateTime? respondedAt;

  const FeedbackItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.subject,
    required this.message,
    required this.rating,
    required this.createdAt,
    required this.status,
    required this.adminResponse,
    this.respondedAt,
  });

  bool get hasResponse => adminResponse.trim().isNotEmpty;
  bool get isAnswered => status == 'Resolved' || hasResponse;

  factory FeedbackItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FeedbackItem(
      id: doc.id,
      userId: d['UserId'] ?? '',
      userName: d['UserName'] ?? '',
      userEmail: d['UserEmail'] ?? '',
      type: d['Type'] ?? 'Query',
      subject: d['Subject'] ?? '',
      message: d['Message'] ?? '',
      rating: (d['Rating'] as num?)?.toInt() ?? 0,
      createdAt: (d['CreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: d['Status'] ?? 'Open',
      adminResponse: d['AdminResponse'] ?? '',
      respondedAt: (d['RespondedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();
  final _db = FirebaseFirestore.instance;

  /// Submits a feedback entry. [rating] is clamped to 0-5.
  Future<void> submit({
    required String type,
    required String message,
    String subject = '',
    int rating = 0,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('Feedbacks').add({
      'UserId': user.uid,
      'UserName': user.displayName ?? '',
      'UserEmail': user.email ?? '',
      'Type': type,
      'Subject': subject,
      'Message': message,
      'Rating': rating.clamp(0, 5),
      'Status': 'Open',
      'AdminResponse': '',
      'CreatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<FeedbackItem>> watchAll() {
    return _db.collection('Feedbacks').snapshots().map((s) {
      final list = s.docs.map(FeedbackItem.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<FeedbackItem>> watchMine() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('Feedbacks')
        .where('UserId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs.map(FeedbackItem.fromDoc).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> setStatus(String id, String status) {
    return _db.collection('Feedbacks').doc(id).update({'Status': status});
  }

  /// Admin writes a reply, which the student then sees on their history list.
  Future<void> reply(String id, String response) {
    return _db.collection('Feedbacks').doc(id).update({
      'AdminResponse': response.trim(),
      'Status': 'Resolved',
      'RespondedAt': FieldValue.serverTimestamp(),
    });
  }
}
