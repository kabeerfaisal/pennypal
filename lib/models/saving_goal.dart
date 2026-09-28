import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/parse.dart';

class GoalMilestone {
  final String title;
  final bool done;

  /// Const so a milestone list can be a compile time constant, which keeps
  /// the edit-in-place copies in the goal screen cheap.
  const GoalMilestone({required this.title, this.done = false});

  factory GoalMilestone.fromMap(Map<String, dynamic> data) {
    return GoalMilestone(
      title: data['Title'] ?? '',
      done: data['Done'] == true,
    );
  }

  Map<String, dynamic> toMap() => {'Title': title, 'Done': done};
}

class SavingGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final String emoji;
  final DateTime? targetDate;
  final double monthlyContribution;
  final List<GoalMilestone> milestones;

  /// Completed goals are moved to the archive instead of being deleted, so the
  /// student keeps the history the SRS asks for.
  final bool archived;
  final DateTime? archivedAt;

  SavingGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.emoji = '🎯',
    this.targetDate,
    this.monthlyContribution = 0,
    this.milestones = const [],
    this.archived = false,
    this.archivedAt,
  });

  double get progress {
    if (targetAmount <= 0) return 0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get remaining => (targetAmount - savedAmount).clamp(0, targetAmount);

  int? get monthsToFinish {
    if (monthlyContribution <= 0) return null;
    return (remaining / monthlyContribution).ceil();
  }

  DateTime? get estimatedFinish {
    final months = monthsToFinish;
    if (months == null) return null;
    return DateTime.now().add(Duration(days: months * 30));
  }

  String get badge {
    if (progress >= 1) return 'Champion';
    if (progress >= 0.75) return 'On fire';
    if (progress >= 0.5) return 'Halfway hero';
    if (progress >= 0.25) return 'Getting started';
    return 'New saver';
  }

  String get motivation {
    if (progress >= 1) {
      return 'You hit the target. Nice work — set the next one.';
    }
    if (progress >= 0.75) {
      return 'Last stretch. Keep the monthly transfer going.';
    }
    if (progress >= 0.5) return 'Past the halfway mark. Stay consistent.';
    if (progress >= 0.25) return 'Momentum is there. Don\'t skip this month.';
    return 'Start with one contribution this week. Small is still progress.';
  }

  factory SavingGoal.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? date;
    final raw = data['TargetDate'] ?? data['targetDate'];
    if (raw is Timestamp) date = raw.toDate();
    DateTime? archivedAt;
    final rawArchived = data['ArchivedAt'] ?? data['archivedAt'];
    if (rawArchived is Timestamp) archivedAt = rawArchived.toDate();
    final marks = <GoalMilestone>[];
    final list = data['Milestones'] ?? data['milestones'];
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          marks.add(GoalMilestone.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return SavingGoal(
      id: id,
      title: data['Title'] ?? data['title'] ?? '',
      targetAmount: asMoney(data['TargetAmount'] ?? data['targetAmount']),
      savedAmount: asMoney(data['SavedAmount'] ?? data['savedAmount']),
      emoji: data['Emoji'] ?? data['emoji'] ?? '🎯',
      targetDate: date,
      monthlyContribution: asMoney(
        data['MonthlyContribution'] ?? data['monthlyContribution'],
      ),
      milestones: marks,
      archived: data['Archived'] == true || data['archived'] == true,
      archivedAt: archivedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Title': title,
      'TargetAmount': targetAmount,
      'SavedAmount': savedAmount,
      'Emoji': emoji,
      'MonthlyContribution': monthlyContribution,
      'Milestones': milestones.map((m) => m.toMap()).toList(),
      if (targetDate != null) 'TargetDate': Timestamp.fromDate(targetDate!),
      'Archived': archived,
      if (archivedAt != null) 'ArchivedAt': Timestamp.fromDate(archivedAt!),
    };
  }

  SavingGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    String? emoji,
    DateTime? targetDate,
    double? monthlyContribution,
    List<GoalMilestone>? milestones,
    bool? archived,
    DateTime? archivedAt,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      emoji: emoji ?? this.emoji,
      targetDate: targetDate ?? this.targetDate,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      milestones: milestones ?? this.milestones,
      archived: archived ?? this.archived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
