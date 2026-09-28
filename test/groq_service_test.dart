import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:penny_pal/services/groq_service.dart';
import 'package:penny_pal/utils/env_config.dart';

/// Starts a throwaway server that writes [frames] in small, deliberately
/// awkward pieces so the SSE line buffering gets stressed.
Future<HttpServerStub> _serve(List<String> frames) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final body = await utf8.decoder.bind(request).join();
    // Echo the payload back through the test so we can assert on it.
    request.response.headers.contentType = ContentType('text', 'event-stream');
    for (final frame in frames) {
      request.response.write(frame);
      await request.response.flush();
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    request.response.write(body);
    await request.response.close();
  });
  return HttpServerStub(server);
}

class HttpServerStub {
  final HttpServer server;
  HttpServerStub(this.server);
  int get port => server.port;
  Future<void> close() => server.close(force: true);
}

String _delta(String reasoning, String content) =>
    'data: ${jsonEncode({
      'choices': [
        {
          'delta': {if (reasoning.isNotEmpty) 'reasoning': reasoning, if (content.isNotEmpty) 'content': content},
        },
      ],
    })}\n';

void main() {
  group('GroqService.streamChat', () {
    late String originalEndpoint;

    setUp(() {
      originalEndpoint = GroqService.endpoint;
      // The key now comes from EnvConfig rather than a compile time define.
      EnvConfig.debugOverride(const {
        'GROQ_API_KEY': 'gsk_test_key',
        'GROQ_MODEL': 'openai/gpt-oss-120b',
      });
    });

    tearDown(() => GroqService.endpoint = originalEndpoint);

    // The service holds one long lived client; releasing it last keeps the
    // test isolate from lingering on an idle keep-alive connection.
    tearDownAll(() => GroqService.instance.dispose());

    test('yields reasoning and content deltas, stopping at [DONE]', () async {
      final stub = await _serve([
        _delta('The student ', ''),
        _delta('asks about food.', ''),
        _delta('', 'Food is '),
        _delta('', 'the top category.'),
        'data: [DONE]\n',
      ]);
      GroqService.endpoint =
          'http://127.0.0.1:${stub.port}/v1/chat/completions';

      final deltas = await GroqService.instance
          .streamChat(
            messages: [
              {'role': 'user', 'content': 'hi'},
            ],
          )
          .toList();
      await stub.close();

      expect(
        deltas.map((d) => d.reasoning).join(),
        'The student asks about food.',
      );
      expect(deltas.map((d) => d.content).join(), 'Food is the top category.');
    });

    test('reassembles frames split across network chunks', () async {
      // A single logical frame delivered in fragments that do not align to
      // newlines, which is what real SSE streams do.
      final stub = await _serve([
        'data: {"choices":[{"delta":{"reasoning":"Split ',
        'ac',
        'ross chunks"}}]}\n',
        'data: {"choices":[{"delta":{"content":"ok"}}]}\ndata: [DONE]\n',
      ]);
      GroqService.endpoint =
          'http://127.0.0.1:${stub.port}/v1/chat/completions';

      final deltas = await GroqService.instance
          .streamChat(
            messages: [
              {'role': 'user', 'content': 'hi'},
            ],
          )
          .toList();
      await stub.close();

      expect(deltas.map((d) => d.reasoning).join(), 'Split across chunks');
      expect(deltas.map((d) => d.content).join(), 'ok');
    });

    test(
      'ignores comment and malformed frames without breaking the stream',
      () async {
        final stub = await _serve([
          ': keep-alive\n',
          'data: {not json}\n',
          _delta('', 'still working'),
          'data: [DONE]\n',
        ]);
        GroqService.endpoint =
            'http://127.0.0.1:${stub.port}/v1/chat/completions';

        final deltas = await GroqService.instance
            .streamChat(
              messages: [
                {'role': 'user', 'content': 'hi'},
              ],
            )
            .toList();
        await stub.close();

        expect(deltas.length, 1);
        expect(deltas.first.content, 'still working');
      },
    );

    test('surfaces a readable message on HTTP 401', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.statusCode = 401;
        request.response.write(
          jsonEncode({
            'error': {'message': 'Invalid API Key'},
          }),
        );
        await request.response.close();
      });
      GroqService.endpoint =
          'http://127.0.0.1:${server.port}/v1/chat/completions';

      Object? caught;
      try {
        await GroqService.instance
            .streamChat(
              messages: [
                {'role': 'user', 'content': 'hi'},
              ],
            )
            .toList();
      } catch (e) {
        caught = e;
      }
      await server.close(force: true);

      expect(caught, isA<GroqException>());
      expect('$caught', contains('rejected'));
      expect('$caught', contains('Invalid API Key'));
    });
  });
}
