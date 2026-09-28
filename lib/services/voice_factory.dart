import 'voice_service.dart';
// speech_to_text has no web implementation, so only native builds get the real
// recogniser. Web and desktop get the no-op, which hides the microphone.
import 'voice_stt_io.dart'
    if (dart.library.js_interop) 'voice_unavailable_io.dart'
    as impl;

/// Returns the speech recogniser for this platform, or the no-op one.
VoiceService createVoiceService() {
  try {
    return impl.SpeechVoiceService();
  } catch (_) {
    return VoiceUnavailable();
  }
}
