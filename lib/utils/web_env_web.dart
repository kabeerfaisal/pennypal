import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Reads the global `env` object that `web/env.js` installs.
Map<String, String> readWebEnv() {
  final raw = (web.window as JSObject).dartify();
  if (raw is! Map) return {};
  final out = <String, String>{};
  raw.forEach((key, value) {
    if (key is String && value != null) out[key] = '$value';
  });
  return out;
}
