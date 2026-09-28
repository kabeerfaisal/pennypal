/// Speech-to-text wrapper.
///
/// Kept behind a tiny interface so the chat screen and the tests do not depend
/// on the plugin directly, and so the app still builds for web and desktop where
/// speech recognition is not available.
abstract class VoiceService {
  bool get isAvailable;
  bool get isListening;
  String get lastError;
  Future<void> init();
  Future<void> start();
  Future<void> stop();
  Future<void> cancel();
  void dispose();
}

/// The no-op implementation used on platforms with no speech engine, and in
/// tests. Every call is safe and [isAvailable] is false, so the UI hides the
/// microphone instead of offering a button that does nothing.
class VoiceUnavailable implements VoiceService {
  @override
  bool get isAvailable => false;

  @override
  bool get isListening => false;

  @override
  String get lastError => 'Voice input is not available on this device';

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
