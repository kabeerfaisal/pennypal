import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// One saved turn in the AI conversation.
///
/// Kept deliberately plain text: the model is sent the same strings, so storing
/// them is enough to rebuild the whole history on the next launch.
class ChatMessage {
  final String role;
  final String content;
  final DateTime at;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.at,
  });

  bool get isUser => role == 'user';

  Map<String, dynamic> toMap() => {
    'Role': role,
    'Content': content,
    'SentAt': FieldValue.serverTimestamp(),
  };

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> d) {
    final raw = d['SentAt'];
    DateTime at;
    if (raw is Timestamp) {
      at = raw.toDate();
    } else if (raw is DateTime) {
      at = raw;
    } else {
      at = DateTime.now();
    }
    return ChatMessage(
      role: '${d['Role'] ?? 'user'}',
      content: '${d['Content'] ?? ''}',
      at: at,
    );
  }
}

/// Stores each student's AI conversation in Firestore.
///
/// FCM is not available on this project, but that does not stop conversations
/// being remembered: every turn is written to
/// `Users/{uid}/Chats/{chatId}/Messages`, so the advisor picks up where the
/// student left off on any device they sign in on.
class ChatHistoryService {
  ChatHistoryService._();
  static final ChatHistoryService instance = ChatHistoryService._();

  /// Turns kept per conversation. Older ones are pruned so a long chat cannot
  /// grow a document collection without bound.
  static const int maxMessages = 100;

  /// How many past conversations a student can switch between.
  static const int maxChats = 12;

  String? _boundUid;
  String? _activeChatId;
  final Map<String, List<ChatMessage>> _cache = {};

  String? get activeChatId => _activeChatId;
  List<ChatMessage> get messages => _cache[_activeChatId] ?? const [];

  /// Called on sign in, and whenever the account changes, so a second student
  /// on the same device never sees the first one's chat.
  void bindTo(String uid) {
    if (_boundUid == uid) return;
    _boundUid = uid;
    _activeChatId = null;
    _cache.clear();
  }

  void reset() {
    _boundUid = null;
    _activeChatId = null;
    _cache.clear();
  }

  CollectionReference<Map<String, dynamic>>? _messagesCol(String chatId) {
    try {
      final uid = _boundUid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      return FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Chats')
          .doc(chatId)
          .collection('Messages');
    } catch (e) {
      // Firebase may have failed to initialise; the in-memory list still works.
      debugPrint('Chat history unavailable: $e');
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? get _chatsCol {
    try {
      final uid = _boundUid ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      return FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('Chats');
    } catch (e) {
      debugPrint('Chat list unavailable: $e');
      return null;
    }
  }

  /// Loads a conversation into the cache. Returns an empty list when there is
  /// nothing stored, which is the normal first-run case.
  Future<List<ChatMessage>> load(String chatId) async {
    final col = _messagesCol(chatId);
    if (col == null) {
      _activeChatId = chatId;
      return messages;
    }
    try {
      final snap = await col.orderBy('SentAt').get();
      final list = snap.docs
          .map((d) => ChatMessage.fromFirestore(d.id, d.data()))
          .where((m) => m.content.trim().isNotEmpty)
          .toList();
      _cache[chatId] = list;
      _activeChatId = chatId;
      return list;
    } catch (e) {
      debugPrint('Chat load: $e');
      _activeChatId = chatId;
      return messages;
    }
  }

  /// Appends one turn. Failures are logged, never thrown, because losing the
  /// reply in the conversation must not break the reply on screen.
  Future<void> append({
    required String chatId,
    required String role,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;
    final entry = ChatMessage(role: role, content: content, at: DateTime.now());

    final list = _cache.putIfAbsent(chatId, () => []);
    list.add(entry);
    if (list.length > maxMessages) {
      list.removeRange(0, list.length - maxMessages);
    }
    _activeChatId ??= chatId;

    final col = _messagesCol(chatId);
    if (col == null) return;
    try {
      await col.add(entry.toMap());
      await _prune(col, chatId);
    } catch (e) {
      debugPrint('Chat append: $e');
    }
  }

  /// Deletes the oldest turns once the conversation passes [maxMessages].
  Future<void> _prune(
    CollectionReference<Map<String, dynamic>> col,
    String chatId,
  ) async {
    try {
      final snap = await col.orderBy('SentAt', descending: true).get();
      if (snap.docs.length <= maxMessages) return;
      final excess = snap.docs.skip(maxMessages);
      final batch = FirebaseFirestore.instance.batch();
      for (final d in excess) {
        batch.delete(d.reference);
      }
      await batch.commit();

      // Keep the conversation list itself from growing forever too.
      final chats = _chatsCol;
      if (chats != null) {
        final chatSnap = await chats.orderBy('LastAt', descending: true).get();
        if (chatSnap.docs.length > maxChats) {
          final drop = chatSnap.docs.skip(maxChats);
          final b2 = FirebaseFirestore.instance.batch();
          for (final d in drop) {
            b2.delete(d.reference);
          }
          await b2.commit();
        }
      }
    } catch (e) {
      debugPrint('Chat prune: $e');
    }
  }

  /// Saves a turn, updating the parent chat document's title and timestamp.
  Future<void> saveTurn({
    required String chatId,
    required String role,
    required String content,
    String? title,
  }) async {
    await append(chatId: chatId, role: role, content: content);

    final chats = _chatsCol;
    if (chats == null) return;
    try {
      final ref = chats.doc(chatId);
      final existing = await ref.get();
      final data = <String, dynamic>{
        'LastAt': FieldValue.serverTimestamp(),
        if (!existing.exists || existing.data()?['Title'] == null)
          'Title': title ?? titleFor(content),
      };
      await ref.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Chat meta: $e');
    }
  }

  /// First few words of the opening question, used as the conversation name.
  @visibleForTesting
  static String titleFor(String question) {
    final clean = question.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return 'New chat';
    return clean.length <= 40 ? clean : '${clean.substring(0, 40)}...';
  }

  Future<void> clear(String chatId) async {
    _cache[chatId] = [];
    final col = _messagesCol(chatId);
    if (col == null) return;
    try {
      final snap = await col.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      await _chatsCol?.doc(chatId).delete();
    } catch (e) {
      debugPrint('Chat clear: $e');
    }
  }

  /// The stored conversations, newest first, for the history sheet.
  Stream<List<Map<String, dynamic>>> watchChats() {
    final col = _chatsCol;
    if (col == null) return const Stream.empty();
    return col
        .orderBy('LastAt', descending: true)
        .limit(maxChats)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }
}
