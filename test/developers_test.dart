import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/widgets/developers_section.dart';

void main() {
  group('developer credits', () {
    test('lists exactly three developers', () {
      expect(kDevelopers.length, 3);
    });

    test('names match the project team', () {
      expect(kDevelopers.map((d) => d.name).toList(), [
        'Muhammad Hashir Edhi',
        'Abdul Kabeer',
        'Muhammad Saad',
      ]);
    });

    test('every developer has a GitHub and LinkedIn link', () {
      for (final d in kDevelopers) {
        expect(d.github, startsWith('https://github.com/'), reason: d.name);
        expect(
          d.linkedin,
          startsWith('https://www.linkedin.com/in/'),
          reason: d.name,
        );
      }
    });

    test('links are the exact addresses supplied', () {
      expect(kDevelopers[0].github, 'https://github.com/hashir-build');
      expect(kDevelopers[1].github, 'https://github.com/kabeerfaisal');
      expect(kDevelopers[2].github, 'https://github.com/MSaad2408b');

      expect(
        kDevelopers[0].linkedin,
        'https://www.linkedin.com/in/muhammad-hashir-247850348/',
      );
      expect(
        kDevelopers[1].linkedin,
        'https://www.linkedin.com/in/kabeersaudagar/',
      );
      expect(
        kDevelopers[2].linkedin,
        'https://www.linkedin.com/in/muhammad-saad-8a8249340/',
      );
    });

    test('every link is a valid absolute URL', () {
      for (final d in kDevelopers) {
        expect(Uri.parse(d.github).hasAbsolutePath, isTrue, reason: d.name);
        expect(Uri.parse(d.linkedin).isAbsolute, isTrue, reason: d.name);
      }
    });

    test('institution is Aptech Garden', () {
      expect(kInstitution, 'APTECH GARDEN STUDENTS');
    });

    test('initials use the first and last name', () {
      // "Muhammad Hashir Edhi" -> Muhammad + Edhi, skipping the middle name.
      expect(kDevelopers[0].initials, 'ME');
      expect(kDevelopers[1].initials, 'AK');
      expect(kDevelopers[2].initials, 'MS');
    });

    test('initials never exceed two characters', () {
      for (final d in kDevelopers) {
        expect(d.initials.length, lessThanOrEqualTo(2), reason: d.name);
      }
    });
  });

  group('DevelopersSection', () {
    testWidgets('renders a card per developer with both link buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DevelopersSection(accent: const Color(0xFF2E7D32)),
            ),
          ),
        ),
      );

      for (final d in kDevelopers) {
        expect(find.text(d.name), findsOneWidget);
      }
      expect(find.text(kInstitution), findsOneWidget);
      expect(find.text('Developed by'), findsOneWidget);
      // A distinct, tappable button per developer per network.
      for (final d in kDevelopers) {
        expect(find.byKey(ValueKey('dev-github-${d.name}')), findsOneWidget);
        expect(find.byKey(ValueKey('dev-linkedin-${d.name}')), findsOneWidget);
      }
      expect(find.byTooltip('GitHub'), findsNWidgets(kDevelopers.length));
      expect(find.byTooltip('LinkedIn'), findsNWidgets(kDevelopers.length));
    });

    testWidgets('brand marks paint without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: SingleChildScrollView(
              child: DevelopersSection(accent: Color(0xFF2E7D32)),
            ),
          ),
        ),
      );

      // Painting happens on the first real frame.
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode without exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: DevelopersSection(accent: Color(0xFF2E7D32)),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Muhammad Saad'), findsOneWidget);
    });

    testWidgets('shows initials for each developer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: SingleChildScrollView(
              child: DevelopersSection(accent: Color(0xFF2E7D32)),
            ),
          ),
        ),
      );

      for (final d in kDevelopers) {
        expect(find.text(d.initials), findsOneWidget);
      }
    });
  });
}
