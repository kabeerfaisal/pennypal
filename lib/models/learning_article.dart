import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/parse.dart';

class LearningArticle {
  final String id;
  final String title;
  final String summary;
  final String body;
  final int order;

  LearningArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    this.order = 0,
  });

  factory LearningArticle.fromFirestore(Map<String, dynamic> data, String id) {
    return LearningArticle(
      id: id,
      title: data['Title'] ?? data['title'] ?? '',
      summary: data['Summary'] ?? data['summary'] ?? '',
      body: data['Body'] ?? data['body'] ?? '',
      order: asInt(data['Order'] ?? data['order']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Title': title,
      'Summary': summary,
      'Body': body,
      'Order': order,
      'UpdatedAt': FieldValue.serverTimestamp(),
    };
  }
}
