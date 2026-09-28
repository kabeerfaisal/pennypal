import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/widgets/ai_markdown.dart';

/// Renders inside a bubble-like constrained box, matching the chat screen.
Widget harness(String markdown, {Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: brightness,
      ),
    ),
    home: Scaffold(
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(maxWidth: 320),
            child: AiMarkdown(
              data: markdown,
              color: isDark ? Colors.white : Colors.black87,
              codeBackground: isDark
                  ? const Color(0xFF15151F)
                  : const Color(0xFFF1F3F5),
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('AiMarkdown', () {
    testWidgets('renders bold as bold text, not literal asterisks', (
      tester,
    ) async {
      await tester.pumpWidget(harness('You spent **\$240** on food.'));

      expect(find.textContaining(r'**'), findsNothing);
      expect(find.textContaining(r'$240'), findsOneWidget);
    });

    testWidgets('renders bullet lists as bullets', (tester) async {
      await tester.pumpWidget(harness('- Cut eating out\n- Raise the goal'));

      expect(find.text('•'), findsNWidgets(2));
      expect(find.textContaining('- Cut'), findsNothing);
    });

    testWidgets('honours single newlines inside a paragraph', (tester) async {
      // LLMs write lists on consecutive lines with no blank line between.
      await tester.pumpWidget(harness('First line\nSecond line'));
      await tester.pumpAndSettle();

      final rich = tester.widget<SelectableText>(
        find.byType(SelectableText).first,
      );
      // softLineBreak keeps the newline instead of joining the lines.
      expect(rich.textSpan!.toPlainText(), contains('\n'));
    });

    testWidgets('renders inline code in a monospace style', (tester) async {
      await tester.pumpWidget(harness('Run `flutter run` first.'));

      final inline = tester.widget<SelectableText>(
        find.byType(SelectableText).first,
      );
      final spans = (inline.textSpan as TextSpan).toPlainText();
      expect(spans, contains('flutter run'));
    });

    testWidgets('long code block wraps instead of overflowing', (tester) async {
      const longLine =
          'this_is_a_very_long_single_line_of_code_that_would_definitely_overflow_a_phone_screen_width';
      await tester.pumpWidget(harness('```dart\n$longLine\n```'));
      await tester.pumpAndSettle();

      // A horizontal scroll view would mean the code can escape the bubble.
      expect(
        find.descendant(
          of: find.byType(AiMarkdown),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('code block fills the bubble width instead of shrink-wrapping', (
      tester,
    ) async {
      await tester.pumpWidget(harness('```\nsome code\n```'));
      await tester.pumpAndSettle();

      // MarkdownBody pins fitContent to true, which left-aligns block children.
      // The code block has to claim the full width regardless.
      final code = tester.widget<Text>(find.text('some code'));
      final codeWidth = tester.getSize(find.byWidget(code)).width;
      final blockquoteLike = tester.getSize(find.byType(AiMarkdown)).width;

      expect(codeWidth, moreOrLessEquals(blockquoteLike, epsilon: 1));
    });

    testWidgets('renders a table with its cells', (tester) async {
      await tester.pumpWidget(
        harness('| Category | Spend |\n| --- | --- |\n| Food | 240 |'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Table), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('renders blockquote decoration', (tester) async {
      await tester.pumpWidget(harness('> Save 20% of every income.'));

      expect(find.textContaining('Save 20%'), findsOneWidget);
    });

    testWidgets('survives unterminated markdown mid-stream', (tester) async {
      // While streaming, closing syntax has not arrived yet. This must not
      // throw or render as an error.
      await tester.pumpWidget(
        harness('**bold and a list:\n- one\n- two\n```dart\nvoid'),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in dark mode without exception', (tester) async {
      await tester.pumpWidget(
        harness(
          '**Bold** and `code`\n\n- item\n\n```\nsnippet\n```',
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('reports tapped links', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: SizedBox(
                  width: 300,
                  child: AiMarkdown(
                    data: 'See [Groq](https://groq.com).',
                    color: Colors.black87,
                    codeBackground: Colors.grey[100]!,
                    onLinkTap: (href) => tapped = href,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('Groq').last);
      await tester.pumpAndSettle();

      expect(tapped, 'https://groq.com');
    });
  });
}
