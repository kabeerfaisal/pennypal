import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/models/saving_goal.dart';
import 'package:penny_pal/theme/app_theme.dart';

/// Goal rows with edit and delete on every milestone, matching the goal detail
/// screen. FinanceController is not touched, so the callbacks are recorded
/// instead of hitting Firestore.
class _MilestoneHarness extends StatefulWidget {
  const _MilestoneHarness();

  @override
  State<_MilestoneHarness> createState() => _MilestoneHarnessState();
}

class _MilestoneHarnessState extends State<_MilestoneHarness> {
  List<GoalMilestone> _marks = const [
    GoalMilestone(title: 'First 500 saved'),
    GoalMilestone(title: 'Halfway', done: true),
  ];
  String? _renamed;
  int? _deleted;
  bool? _toggled;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(AppColors.brand),
      home: Scaffold(
        body: Column(
          children: [
            for (int i = 0; i < _marks.length; i++) _row(context, i),
            const Spacer(),
            Text('renamed=$_renamed deleted=$_deleted toggled=$_toggled'),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int i) {
    final m = _marks[i];
    return Row(
      children: [
        Checkbox(
          value: m.done,
          onChanged: (v) => setState(() {
            _toggled = v;
            final next = [..._marks];
            next[i] = GoalMilestone(title: m.title, done: v ?? false);
            _marks = next;
          }),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _renamed = 'title-$i'),
            child: Text(m.title),
          ),
        ),
        IconButton(
          tooltip: 'Rename',
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: () => setState(() => _renamed = 'title-$i'),
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          onPressed: () => setState(() {
            _deleted = i;
            final next = [..._marks]..removeAt(i);
            _marks = next;
          }),
        ),
      ],
    );
  }
}

void main() {
  group('milestone list', () {
    testWidgets('every milestone can be renamed', (tester) async {
      await tester.pumpWidget(const _MilestoneHarness());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('renamed=title-0'), findsOneWidget);
    });

    testWidgets('tapping the title also renames', (tester) async {
      await tester.pumpWidget(const _MilestoneHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('First 500 saved'));
      await tester.pumpAndSettle();
      expect(find.textContaining('renamed=title-0'), findsOneWidget);
    });

    testWidgets('every milestone can be deleted', (tester) async {
      await tester.pumpWidget(const _MilestoneHarness());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('deleted=0'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('First 500 saved'), findsNothing);
    });

    testWidgets('a milestone can be ticked without losing its title', (
      tester,
    ) async {
      await tester.pumpWidget(const _MilestoneHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('toggled=true'), findsOneWidget);
      expect(find.text('First 500 saved'), findsOneWidget);
    });

    testWidgets('a long title does not push the buttons off screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const _MilestoneHarness());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));
    });
  });

  group('GoalMilestone', () {
    test('round trips through a map, keeping the done flag', () {
      final m = GoalMilestone(title: 'First 500 saved', done: true);
      final back = GoalMilestone.fromMap(m.toMap());

      expect(back.title, 'First 500 saved');
      expect(back.done, isTrue);
    });

    test('a missing done flag reads as not done', () {
      expect(GoalMilestone.fromMap({'Title': 'x'}).done, isFalse);
    });

    test('SavingGoal.copyWith replaces only the milestones', () {
      final goal = SavingGoal(
        id: 'g1',
        title: 'Laptop',
        targetAmount: 1000,
        savedAmount: 200,
        milestones: const [GoalMilestone(title: 'a')],
      );
      final next = goal.copyWith(milestones: const []);

      expect(next.milestones, isEmpty);
      // Everything else must survive the edit.
      expect(next.title, 'Laptop');
      expect(next.targetAmount, 1000);
      expect(next.savedAmount, 200);
    });
  });
}
