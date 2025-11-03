import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// --- STATE MODEL ---
class VoiceAssistantState {
  final bool isRecording;
  final bool isProcessing;
  final String transcription;
  final String response;
  final Map<String, dynamic> analysis;

  const VoiceAssistantState({
    this.isRecording = false,
    this.isProcessing = false,
    this.transcription = '',
    this.response = '',
    this.analysis = const {},
  });

  VoiceAssistantState copyWith({
    bool? isRecording,
    bool? isProcessing,
    String? transcription,
    String? response,
    Map<String, dynamic>? analysis,
  }) {
    return VoiceAssistantState(
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      transcription: transcription ?? this.transcription,
      response: response ?? this.response,
      analysis: analysis ?? this.analysis,
    );
  }
}

/// --- PROVIDER NOTIFIER ---
class VoiceAssistantNotifier extends StateNotifier<VoiceAssistantState> {
  final RecorderController recorderController = RecorderController();
  final supabase = Supabase.instance.client;

  VoiceAssistantNotifier() : super(const VoiceAssistantState());

  String? recordedFilePath;

  /// 🎙️ Start recording
  Future<void> startRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/input_audio.m4a';
      recordedFilePath = filePath;

      await recorderController.record(path: filePath);
      state = state.copyWith(isRecording: true, transcription: '', response: '', analysis: {});
    } catch (e) {
      state = state.copyWith(response: 'Error starting recording: $e');
    }
  }

  /// ⏹ Stop recording and process
  Future<void> stopRecording() async {
    try {
      await recorderController.stop();
      state = state.copyWith(isRecording: false, isProcessing: true);

      if (recordedFilePath == null) {
        state = state.copyWith(isProcessing: false, response: 'No audio recorded.');
        return;
      }

      await _sendAudioToBackend(recordedFilePath!);
    } catch (e) {
      state = state.copyWith(isProcessing: false, response: 'Error stopping recording: $e');
    }
  }

  /// ☁️ Upload to Supabase
  Future<String?> uploadAudioToSupabase(String filePath) async {
    try {
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final file = File(filePath);

      await supabase.storage.from('audio_uploads').upload(fileName, file);
      final publicUrl = supabase.storage.from('audio_uploads').getPublicUrl(fileName);

      print('✅ Uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Upload failed: $e');
      return null;
    }
  }

  /// 🚀 Send audio to backend for transcription + reasoning
  Future<void> _sendAudioToBackend(String path) async {
    try {
      final audioUrl = await uploadAudioToSupabase(path);
      if (audioUrl == null) {
        state = state.copyWith(isProcessing: false, response: 'Failed to upload audio.');
        return;
      }

      final uri = Uri.parse("https://kc12345-tamubot.hf.space/transcribe");
      final body = jsonEncode({"url": audioUrl});

      final response = await http.post(uri, headers: {"Content-Type": "application/json"}, body: body);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == "success") {
          state = state.copyWith(
            isProcessing: false,
            transcription: json["transcription"] ?? '',
            response: json["analysis"]?["response"] ?? '',
            analysis: Map<String, dynamic>.from(json["analysis"] ?? {}),
          );
        } else {
          state = state.copyWith(isProcessing: false, response: json["message"] ?? "Processing error");
        }
      } else {
        state = state.copyWith(isProcessing: false, response: "HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print('❌ Backend error: $e');
      state = state.copyWith(isProcessing: false, response: 'Error: $e');
    }
  }

  /// 💬 Send text chat messages
  Future<void> sendChat(String message) async {
    try {
      state = state.copyWith(isProcessing: true);
      final uri = Uri.parse("https://kc12345-tamubot.hf.space/chat");

      final response = await http.post(uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"message": message}));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        state = state.copyWith(
          isProcessing: false,
          response: json["response"] ?? "No response",
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          response: "Chat error: ${response.body}",
        );
      }
    } catch (e) {
      state = state.copyWith(isProcessing: false, response: 'Connection error: $e');
    }
  }

  /// 🧹 Reset
  void clearState() {
    state = const VoiceAssistantState();
  }
}

/// --- PROVIDER INSTANCE ---
final voiceAssistantProvider =
    StateNotifierProvider<VoiceAssistantNotifier, VoiceAssistantState>(
  (ref) => VoiceAssistantNotifier(),
);
