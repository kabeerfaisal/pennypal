import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

// The web build cannot read the project directory, so it also gets its values
// from `web/env.js`. Native builds use the stub.
import 'web_env_stub.dart' if (dart.library.js_interop) 'web_env_web.dart';

/// Loads configuration without needing `--dart-define` on every run.
///
/// Order of precedence, lowest to highest:
///  1. `web/env.js`, for the web target when the asset is missing.
///  2. A `.env` file next to the project, for desktop and web dev servers.
///  3. `assets/env.txt`, a bundled copy generated from `.env`. This is the one
///     that works on Android, where the project directory does not exist.
///  4. `--dart-define`, so CI and the run script can always override.
class EnvConfig {
  EnvConfig._();

  static Map<String, String> _values = {};
  static String _source = 'not loaded';
  static bool _loaded = false;

  /// Must be awaited before anything reads a value.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    final layers = <String, Map<String, String>>{
      'web/env.js': readWebEnv(),
      '.env file': await _fromEnvFile(),
      'assets/env.txt': await _fromBundledAsset(),
      '--dart-define': _fromDartDefine(),
    };

    var merged = <String, String>{};
    layers.forEach((label, values) {
      if (values.isEmpty) return;
      merged = {...merged, ...values};
      // Keep pointing at the layer that supplied the key we actually use.
      if (values.containsKey('GROQ_API_KEY')) _source = label;
    });
    _values = merged;
  }

  static String get(String key, {String fallback = ''}) =>
      _values[key] ?? fallback;

  static String? get groqApiKey {
    final key = get('GROQ_API_KEY').trim();
    if (debugRejects(key)) return null;
    return key;
  }

  /// True when a value is empty or still a template placeholder.
  @visibleForTesting
  static bool debugRejects(String value) {
    final v = value.trim();
    if (v.isEmpty) return true;
    if (v.contains('PASTE') || v.startsWith('YOUR_')) return true;
    return false;
  }

  static String get groqModel =>
      get('GROQ_MODEL', fallback: 'openai/gpt-oss-120b');

  static bool get hasGroqKey => groqApiKey != null;

  /// Shown in the app when the key is missing, so the cause is obvious.
  static String describe() {
    final key = get('GROQ_API_KEY');
    if (key.isEmpty) {
      return 'No GROQ_API_KEY found. Add it to the .env file in the project '
          'root, run .\\sync-env.ps1 once, then restart the app.';
    }
    if (groqApiKey == null) {
      return 'GROQ_API_KEY is still the placeholder. Put your real gsk_ key '
          'in .env';
    }
    return 'GROQ_API_KEY loaded from $_source';
  }

  static Map<String, String> _fromDartDefine() {
    const key = String.fromEnvironment('GROQ_API_KEY');
    if (key.isEmpty) return {};
    return {
      'GROQ_API_KEY': key,
      'GROQ_MODEL': const String.fromEnvironment(
        'GROQ_MODEL',
        defaultValue: 'openai/gpt-oss-120b',
      ),
    };
  }

  static Future<Map<String, String>> _fromEnvFile() async {
    if (kIsWeb) return {};
    for (final name in const ['.env', 'api-keys.json']) {
      final file = File(name);
      if (!file.existsSync()) continue;
      try {
        final text = await file.readAsString();
        final parsed = name.endsWith('.json')
            ? _parseJson(text)
            : _parseEnv(text);
        if (parsed.isNotEmpty) return parsed;
      } catch (e) {
        debugPrint('Could not read $name: $e');
      }
    }
    return {};
  }

  /// The bundled copy, which is the only source that exists on Android and on a
  /// deployed web build. `sync-env.ps1` writes it from `.env`.
  static Future<Map<String, String>> _fromBundledAsset() async {
    try {
      final text = await rootBundle.loadString(_assetPath);
      final parsed = _parseEnv(text);
      if (parsed.isEmpty) {
        debugPrint('$_assetPath was loaded but held no KEY=value lines');
      }
      return parsed;
    } catch (_) {
      // Expected when the asset has not been generated yet.
      return {};
    }
  }

  static Map<String, String> _parseEnv(String text) => debugParse(text);

  /// Exposed for tests so the format is checked without a filesystem.
  @visibleForTesting
  static Map<String, String> debugParse(String text) {
    final out = <String, String>{};
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final split = line.split('=');
      if (split.length < 2) continue;
      final key = split.first.trim();
      final value = split.sublist(1).join('=').trim();
      if (key.isEmpty || value.isEmpty) continue;
      out[key] = value;
    }
    return out;
  }

  static Map<String, String> _parseJson(String text) {
    final out = <String, String>{};
    for (final m in RegExp(r'"([^"]+)"\s*:\s*"([^"]*)"').allMatches(text)) {
      out[m.group(1)!] = m.group(2)!;
    }
    return out;
  }

  /// Lets tests inject values without touching the filesystem.
  @visibleForTesting
  static void debugOverride(Map<String, String> values) {
    _values = values;
    _source = 'test';
    _loaded = true;
  }

  /// Lets tests reset between cases.
  @visibleForTesting
  static void debugReset() {
    _values = {};
    _source = 'not loaded';
    _loaded = false;
  }
}

/// Must match the `assets:` entry in pubspec.yaml.
const String _assetPath = 'assets/env.txt';
