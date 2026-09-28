import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/utils/env_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => EnvConfig.debugReset());

  group('EnvConfig parsing', () {
    test('reads KEY=value lines and skips comments and blanks', () {
      final parsed = EnvConfig.debugParse('''
# a comment

GROQ_API_KEY=gsk_abc123
GROQ_MODEL=openai/gpt-oss-120b

  INDENTED=yes
''');
      expect(parsed['GROQ_API_KEY'], 'gsk_abc123');
      expect(parsed['GROQ_MODEL'], 'openai/gpt-oss-120b');
      expect(parsed['INDENTED'], 'yes');
      expect(parsed.length, 3);
    });

    test('keeps everything after the first equals sign', () {
      final parsed = EnvConfig.debugParse('TOKEN=abc=def==ghi');
      expect(parsed['TOKEN'], 'abc=def==ghi');
    });

    test('a line with no equals sign is ignored', () {
      expect(EnvConfig.debugParse('GARBAGE\nA=1'), {'A': '1'});
    });
  });

  group('EnvConfig key detection', () {
    test('a real gsk key is accepted', () {
      EnvConfig.debugOverride({'GROQ_API_KEY': 'gsk_LKLo2fwTvsZ1'});
      expect(EnvConfig.hasGroqKey, isTrue);
      expect(EnvConfig.groqApiKey, 'gsk_LKLo2fwTvsZ1');
    });

    test('placeholders are rejected so the app can say what is wrong', () {
      for (final bad in const ['', '   ', 'PASTE_YOUR_KEY', 'YOUR_KEY_HERE']) {
        EnvConfig.debugOverride({'GROQ_API_KEY': bad});
        expect(EnvConfig.hasGroqKey, isFalse, reason: 'should reject "$bad"');
      }
    });

    test('describe points at the fix when nothing is configured', () {
      EnvConfig.debugOverride({});
      expect(EnvConfig.hasGroqKey, isFalse);
      expect(EnvConfig.describe(), contains('.env'));
      expect(EnvConfig.describe(), contains('sync-env.ps1'));
    });

    test('describe separates a placeholder from a missing key', () {
      EnvConfig.debugOverride({'GROQ_API_KEY': 'PASTE_YOUR_KEY'});
      expect(EnvConfig.describe(), contains('placeholder'));
    });

    test('the model has a working default', () {
      EnvConfig.debugOverride({});
      expect(EnvConfig.groqModel, isNotEmpty);
    });
  });

  group('EnvConfig bundled asset', () {
    test('the generated asset holds the real key', () async {
      // This is the file sync-env.ps1 writes and pubspec.yaml bundles. If it
      // ever drifts from .env the Android build silently loses the AI.
      final text = await rootBundle.loadString('assets/env.txt');
      final parsed = EnvConfig.debugParse(text);

      expect(parsed['GROQ_API_KEY'], startsWith('gsk_'));
      expect(EnvConfig.debugRejects(parsed['GROQ_API_KEY']!), isFalse);
      expect(parsed['GROQ_MODEL'], isNotEmpty);
    });

    test('load picks the key up from the bundled asset', () async {
      await EnvConfig.load();
      expect(EnvConfig.hasGroqKey, isTrue, reason: EnvConfig.describe());
      expect(EnvConfig.groqApiKey, startsWith('gsk_'));
    });

    test('load is safe to call twice', () async {
      await EnvConfig.load();
      final first = EnvConfig.groqApiKey;
      await EnvConfig.load();
      expect(EnvConfig.groqApiKey, first);
    });
  });
}
