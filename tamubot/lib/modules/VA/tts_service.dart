import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  TtsService() {
    _initializeTts();
  }

  void _initializeTts() {
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });

    _flutterTts.setErrorHandler((message) {
      _isPlaying = false;
    });
  }

  Future<void> speak(
    String text, {
    double rate = 0.5,
    double pitch = 1.0,
    double volume = 1.0,
    String language = 'en-US',
  }) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.setPitch(pitch);
    await _flutterTts.setVolume(volume);
    
    await _flutterTts.speak(text);
    _isPlaying = true;
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }

  Future<void> togglePlayStop(String text) async {
    if (_isPlaying) {
      await stop();
    } else {
      await speak(text);
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}