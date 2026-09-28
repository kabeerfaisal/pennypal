import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/widgets/receipt_widgets.dart';

const _accent = Colors.redAccent;

Widget field({
  String receiptData = '',
  bool preparing = false,
  VoidCallback? onPick,
  VoidCallback? onRemove,
}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ReceiptPickerField(
          receiptData: receiptData,
          preparing: preparing,
          accent: _accent,
          onPick: () => onPick?.call(),
          onRemove: () => onRemove?.call(),
        ),
      ),
    ),
  );
}

// Smallest possible valid JPEG, so Image.memory has real bytes to decode.
const _tinyJpeg =
    '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a'
    'HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAA'
    'AAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==';

void main() {
  group('ReceiptPickerField', () {
    testWidgets('empty state offers the add button', (tester) async {
      var picked = 0;
      await tester.pumpWidget(field(onPick: () => picked++));

      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('optional'), findsOneWidget);
      expect(find.text('Add receipt photo'), findsOneWidget);

      await tester.tap(find.text('Add receipt photo'));
      expect(picked, 1);
    });

    testWidgets('preparing state hides the button and shows a spinner', (
      tester,
    ) async {
      await tester.pumpWidget(field(preparing: true));

      expect(find.text('Preparing receipt...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Add receipt photo'), findsNothing);
    });

    testWidgets('attached state shows the remove button', (tester) async {
      var removed = 0;
      await tester.pumpWidget(
        field(receiptData: _tinyJpeg, onRemove: () => removed++),
      );
      await tester.pump();

      expect(find.text('Add receipt photo'), findsNothing);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(removed, 1);
    });

    testWidgets('attached state decodes a real image from base64', (
      tester,
    ) async {
      await tester.pumpWidget(field(receiptData: _tinyJpeg));
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('attached state falls back on corrupt data without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(field(receiptData: 'not-valid-base64 !!!'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      // The remove button must still work so the student is not stuck.
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('attached state shows the stored size', (tester) async {
      await tester.pumpWidget(field(receiptData: _tinyJpeg));
      await tester.pump();

      // The sample image is tiny, so the label can be either unit.
      expect(find.textContaining(RegExp(r'\d+\s?(B|KB|MB)')), findsOneWidget);
    });

    testWidgets('preparing wins over an existing receipt', (tester) async {
      await tester.pumpWidget(field(receiptData: _tinyJpeg, preparing: true));

      expect(find.text('Preparing receipt...'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('ReceiptThumb', () {
    Widget thumb({String data = '', VoidCallback? onTap}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: ReceiptThumb(
              data: data,
              color: Colors.orange,
              fallbackIcon: Icons.fastfood,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    testWidgets('no data renders the category icon', (tester) async {
      await tester.pumpWidget(thumb());
      expect(find.byIcon(Icons.fastfood), findsOneWidget);
    });

    testWidgets('with data renders an image, not the icon', (tester) async {
      await tester.pumpWidget(thumb(data: _tinyJpeg));
      await tester.pump();

      expect(find.byIcon(Icons.fastfood), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('corrupt data falls back to the category icon', (tester) async {
      await tester.pumpWidget(thumb(data: 'not-valid-base64 !!!'));
      await tester.pump();

      expect(find.byIcon(Icons.fastfood), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is tappable when a receipt exists', (tester) async {
      var taps = 0;
      await tester.pumpWidget(thumb(data: _tinyJpeg, onTap: () => taps++));
      await tester.pump();

      await tester.tap(find.byType(Image));
      expect(taps, 1);
    });
  });
}
