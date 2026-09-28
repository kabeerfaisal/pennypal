import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'voice_service.dart';

/// Real speech-to-text, built on `speech_to_text`.
///
/// The plugin has no web implementation, so this file is only compiled where
/// it exists; web and desktop fall back to [VoiceUnavailable] through the
/// conditional import in `voice_io.dart`.
class SpeechVoiceService implements VoiceService {
  SpeechVoiceService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _available = false;
  bool _listening = false;
  String _error = '';

  /// Called with each partial result so the caller can show it live.
  void Function(String text, bool isFinal)? onResult;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _listening;

  @override
  String get lastError => _error;

  @override
  Future<void> init() async {
    try {
      _available = await _speech.initialize(
        onError: (e) {
          _error = e.errorMsg;
          _listening = false;
        },
        onStatus: (status) {
          _listening = status == 'listening' || status == 'done';
        },
        debugLogging: false,
      );
      if (!_available) {
        _error = 'Speech recognition is not available on this device';
      }
    } catch (e) {
      _available = false;
      _error = 'Could not start the microphone: $e';
      debugPrint('Voice init: $e');
    }
  }

  @override
  Future<void> start() async {
    if (!_available) return;
    _error = '';
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult?.call(result.recognizedWords, result.finalResult);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          // Pause after this much silence rather than cutting the student off
          // mid sentence, and give up after a generous window.
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(seconds: 40),
        ),
      );
      _listening = true;
    } catch (e) {
      _listening = false;
      _error = 'Could not start listening: $e';
      debugPrint('Voice start: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (!_available) return;
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('Voice stop: $e');
    }
    _listening = false;
  }

  @override
  Future<void> cancel() async {
    if (!_available) return;
    try {
      await _speech.cancel();
    } catch (e) {
      debugPrint('Voice cancel: $e');
    }
    _listening = false;
  }

  @override
  void dispose() {
    _speech.cancel();
  }
}
