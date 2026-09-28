import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/env_config.dart';

/// One incremental slice of a streamed chat completion.
///
/// GPT-OSS models send the chain of thought in [reasoning] and the user facing
/// answer in [content], so both are surfaced separately to the UI.
class GroqDelta {
  final String reasoning;
  final String content;

  const GroqDelta({this.reasoning = '', this.content = ''});

  bool get isEmpty => reasoning.isEmpty && content.isEmpty;
}

class GroqException implements Exception {
  final String message;
  const GroqException(this.message);

  @override
  String toString() => message;
}

/// Minimal Dart client for Groq's OpenAI compatible chat completions API.
///
/// The key comes from `EnvConfig`, which reads `.env` at runtime, so no
/// `--dart-define` is needed. See https://console.groq.com/keys
class GroqService {
  GroqService._();
  static final GroqService instance = GroqService._();

  static const String _defaultEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Overridable so the SSE parser can be exercised against a local server.
  @visibleForTesting
  static String endpoint = _defaultEndpoint;

  /// Reasoning models burn tokens on thinking, so the 1024 default is usually
  /// not enough to also produce an answer.
  static const int _maxCompletionTokens = 2048;

  final _client = http.Client();

  static String get apiKey => EnvConfig.groqApiKey ?? '';
  static String get model => EnvConfig.groqModel;

  bool get isConfigured => EnvConfig.hasGroqKey;

  /// Why [isConfigured] is false, phrased for the user to act on.
  String get configHint => EnvConfig.describe();

  /// Streams a completion. Cancelling the subscription aborts the request.
  Stream<GroqDelta> streamChat({
    required List<Map<String, String>> messages,
    String? reasoningEffort,
  }) async* {
    if (!isConfigured) {
      throw const GroqException(
        'Groq API key missing. Run with '
        '--dart-define=GROQ_API_KEY=gsk_...',
      );
    }

    final body = <String, Object?>{
      'model': model,
      'messages': messages,
      'stream': true,
      'temperature': 0.6,
      'top_p': 0.95,
      'max_completion_tokens': _maxCompletionTokens,
    };
    if (reasoningEffort != null) body['reasoning_effort'] = reasoningEffort;

    final request = http.Request('POST', Uri.parse(endpoint))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode(body);

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      final raw = await response.stream.bytesToString();
      throw GroqException(_readError(response.statusCode, raw));
    }

    // Server-sent events are newline delimited JSON, but a network chunk can
    // split a line anywhere, so hold the tail back until it is complete.
    var buffer = '';
    await for (final piece in response.stream.transform(utf8.decoder)) {
      buffer += piece;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;

        final data = trimmed.substring(5).trim();
        if (data == '[DONE]') return;
        if (data.isEmpty) continue;

        final delta = _parseDelta(data);
        if (delta != null && !delta.isEmpty) yield delta;
      }
    }
  }

  GroqDelta? _parseDelta(String data) {
    try {
      final json = jsonDecode(data);
      if (json is! Map<String, dynamic>) return null;
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map<String, dynamic>) return null;
      final delta = first['delta'];
      if (delta is! Map<String, dynamic>) return null;

      return GroqDelta(
        reasoning: delta['reasoning'] as String? ?? '',
        content: delta['content'] as String? ?? '',
      );
    } catch (_) {
      // A malformed keep-alive frame should not kill the stream.
      return null;
    }
  }

  String _readError(int status, String raw) {
    String detail = raw;
    try {
      final json = jsonDecode(raw);
      if (json is Map && json['error'] is Map) {
        detail = '${(json['error'] as Map)['message']}';
      }
    } catch (_) {}

    if (status == 401) return 'Groq API key rejected (401). $detail';
    if (status == 429) return 'Groq rate limit hit (429). Try again shortly.';
    if (status == 400) return 'Groq rejected the request: $detail';
    return 'Groq request failed ($status). $detail';
  }

  void dispose() => _client.close();
}
