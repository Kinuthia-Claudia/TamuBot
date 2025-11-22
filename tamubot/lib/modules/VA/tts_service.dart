// lib/modules/assistant/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped }

class TtsService {
  FlutterTts flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;

  TtsState get ttsState => _ttsState;
  bool get isPlaying => _ttsState == TtsState.playing;

  TtsService() {
    _initTts();
  }

  void _initTts() {
    flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
    });

    flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.stopped;
    });
  }

  Future<void> speak(
    String text, {
    double rate = 0.5,
    double pitch = 1.0,
    double volume = 1.0,
    String language = 'en-US',
  }) async {
    if (text.isNotEmpty) {
      await flutterTts.setLanguage(language);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);
      await flutterTts.setVolume(volume);
      await flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await flutterTts.stop();
    _ttsState = TtsState.stopped;
  }

  // Simple play/stop toggle
  Future<void> togglePlayStop(String text, {
    double rate = 0.5,
    double pitch = 1.0,
    double volume = 1.0,
    String language = 'en-US',
  }) async {
    if (isPlaying) {
      await stop();
    } else {
      await speak(text, rate: rate, pitch: pitch, volume: volume, language: language);
    }
  }

  Future<List<dynamic>> getLanguages() async {
    return await flutterTts.getLanguages;
  }

  Future<List<dynamic>> getVoices() async {
    return await flutterTts.getVoices;
  }

  void dispose() {
    flutterTts.stop();
  }
}