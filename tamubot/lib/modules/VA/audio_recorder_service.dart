import 'package:audio_waveforms/audio_waveforms.dart';

class AudioRecorderService {
  late RecorderController recorderController;

  AudioRecorderService() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  Future<void> startRecording() async {
    try {
      await recorderController.record();
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await recorderController.stop();
      return path;
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  void dispose() {
    recorderController.dispose();
  }
}