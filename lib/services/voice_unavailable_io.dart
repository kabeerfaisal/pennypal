import 'voice_service.dart';

/// Web and desktop stand-in. The factory picks this file whenever
/// `dart.library.js_interop` is absent, which is where `speech_to_text` has no
/// implementation. Exposing the same class name keeps the factory simple.
class SpeechVoiceService implements VoiceService {
  @override
  bool get isAvailable => false;

  @override
  bool get isListening => false;

  @override
  String get lastError => 'Voice input needs the Android or iOS app';

  @override
  Future<void> init() async {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  @override
  void dispose() {}
}
