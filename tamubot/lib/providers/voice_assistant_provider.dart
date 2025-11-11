import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Chat message model
class ChatMessage {
  final String role; // "user" or "assistant"
  final String text;

  ChatMessage({required this.role, required this.text});
}

/// Provider state
class VoiceAssistantState {
  final bool isRecording;
  final bool isProcessing;
  final bool isSpeaking;
  final String? recordedFilePath;
  final String transcription;
  final String stage; // start | ingredients | instructions | feedback | complete
  final List<ChatMessage> messages;
  final bool feedbackSubmitted;
  final String? response; // last assistant response (plain)
  final bool showRecordingOptions; // NEW: Controls whether to show options dialog

  const VoiceAssistantState({
    this.isRecording = false,
    this.isProcessing = false,
    this.isSpeaking = false,
    this.recordedFilePath,
    this.transcription = '',
    this.stage = 'start',
    this.messages = const [],
    this.feedbackSubmitted = false,
    this.response,
    this.showRecordingOptions = false, // NEW
  });

  VoiceAssistantState copyWith({
    bool? isRecording,
    bool? isProcessing,
    bool? isSpeaking,
    String? recordedFilePath,
    String? transcription,
    String? stage,
    List<ChatMessage>? messages,
    bool? feedbackSubmitted,
    String? response,
    bool? showRecordingOptions, // NEW
  }) {
    return VoiceAssistantState(
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      recordedFilePath: recordedFilePath ?? this.recordedFilePath,
      transcription: transcription ?? this.transcription,
      stage: stage ?? this.stage,
      messages: messages ?? this.messages,
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
      response: response ?? this.response,
      showRecordingOptions: showRecordingOptions ?? this.showRecordingOptions, // NEW
    );
  }
}

/// Provider
final voiceAssistantProvider =
    StateNotifierProvider<VoiceAssistantNotifier, VoiceAssistantState>(
        (ref) => VoiceAssistantNotifier());

class VoiceAssistantNotifier extends StateNotifier<VoiceAssistantState> {
  VoiceAssistantNotifier() : super(const VoiceAssistantState());

  final RecorderController recorderController = RecorderController();
  final FlutterTts flutterTts = FlutterTts();
  final supabase = Supabase.instance.client;

  /// Initialize TTS settings (call once)
  Future<void> initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    flutterTts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
  }

  /// Speak text locally
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    state = state.copyWith(isSpeaking: true);
    try {
      await flutterTts.speak(text);
    } catch (e) {
      state = state.copyWith(isSpeaking: false);
      print("TTS error: $e");
    }
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  /// Start recording
  Future<void> startRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/input_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Clear any previous state
      state = state.copyWith(
        recordedFilePath: null,
        showRecordingOptions: false,
      );
      
      await recorderController.record(path: path);
      state = state.copyWith(
        isRecording: true,
        transcription: '',
        recordedFilePath: path,
      );
    } catch (e) {
      state = state.copyWith(
          isRecording: false, 
          response: 'Error starting recording: $e'
      );
      print("startRecording error: $e");
    }
  }

  /// Stop recording and show options
  Future<void> stopRecording() async {
    try {
      await recorderController.stop();
      state = state.copyWith(
        isRecording: false,
        showRecordingOptions: true, // Show options after stopping
      );
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        showRecordingOptions: false,
        response: 'Error stopping recording: $e'
      );
      print("stopRecording error: $e");
    }
  }

  /// Hide recording options
  void hideRecordingOptions() {
    state = state.copyWith(showRecordingOptions: false);
  }

  /// Discard recorded audio
  Future<void> discardRecording() async {
    final String? filePath = state.recordedFilePath;
    
    // Hide options and clear file path
    state = state.copyWith(
      recordedFilePath: null,
      showRecordingOptions: false,
    );
    
    // Delete file in background
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          print("Recording discarded and file deleted");
        }
      } catch (e) {
        print("Error deleting file: $e");
      }
    }
  }

  /// Send recorded audio to backend
  Future<void> sendRecordedAudio() async {
    final String? filePath = state.recordedFilePath;
    if (filePath == null) {
      state = state.copyWith(response: "No recording to send.");
      return;
    }

    // Hide options immediately
    state = state.copyWith(
      showRecordingOptions: false,
      isProcessing: true,
    );

    try {
      final audioUrl = await uploadAudioToSupabase(filePath);
      if (audioUrl == null) {
        state = state.copyWith(
          isProcessing: false,
          recordedFilePath: null,
          response: "Upload failed.",
        );
        return;
      }

      final uri = Uri.parse("https://kc12345-tamubot.hf.space/transcribe");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "url": audioUrl,
          "user_id": supabase.auth.currentUser?.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stage = data["stage"] ?? "start";
        final ingredients = data["ingredients"] ?? "";
        final prompt = data["prompt"] ?? "";
        final transcription = data["transcription"] ?? "";

        final botReply = (stage == "ingredients")
            ? "Ingredients:\n$ingredients\n\n$prompt"
            : (stage == "instructions")
                ? " Steps:\n${data["instructions"] ?? ""}\n\n${data["prompt"] ?? ""}"
                : (data["prompt"] ?? "");

        final msgs = [
          ...state.messages,
          ChatMessage(role: "user", text: transcription),
          ChatMessage(role: "assistant", text: botReply),
        ];

        state = state.copyWith(
          isProcessing: false,
          recordedFilePath: null,
          transcription: transcription,
          stage: stage,
          messages: msgs,
          response: botReply,
        );

        await speak(botReply);
      } else {
        state = state.copyWith(
          isProcessing: false,
          recordedFilePath: null,
          response: "Error ${response.statusCode}",
        );
        print("transcribe API error: ${response.body}");
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        recordedFilePath: null,
        response: "Send audio error: $e",
      );
      print("sendRecordedAudio error: $e");
    }
  }

  /// Upload file to Supabase storage and return public URL
  Future<String?> uploadAudioToSupabase(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await supabase.storage.from('audio_uploads').upload(fileName, file);
      final pub = supabase.storage.from('audio_uploads').getPublicUrl(fileName);
      print("Uploaded: $pub");
      return pub;
    } catch (e) {
      print("uploadAudioToSupabase error: $e");
      return null;
    }
  }

  /// Send text chat
  Future<void> sendChat(String message) async {
    try {
      state = state.copyWith(isProcessing: true);

      final uri = Uri.parse("https://kc12345-tamubot.hf.space/chat");
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": message,
          "user_id": supabase.auth.currentUser?.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stage = data["stage"] ?? "start";
        final ingredients = data["ingredients"] ?? "";
        final prompt = data["prompt"] ?? "";
        final botReply = (stage == "ingredients")
            ? " Ingredients:\n$ingredients\n\n$prompt"
            : (stage == "instructions")
                ? " Steps:\n${data["instructions"] ?? ""}\n\n${data["prompt"] ?? ""}"
                : (data["prompt"] ?? data["response"] ?? "");

        final msgs = [
          ...state.messages,
          ChatMessage(role: "user", text: message),
          ChatMessage(role: "assistant", text: botReply),
        ];

        state = state.copyWith(
          isProcessing: false,
          stage: stage,
          messages: msgs,
          response: botReply,
        );

        await speak(botReply);
      } else {
        state = state.copyWith(
          isProcessing: false,
          response: "Chat error: ${response.body}",
        );
        print("chat api error: ${response.body}");
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        response: "Chat send error: $e",
      );
      print("sendChat error: $e");
    }
  }

  /// Submit feedback
  Future<void> submitFeedback(int rating, String comments) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(response: "Please sign in to submit feedback.");
        return;
      }

      final insert = {
        'user_id': user.id,
        'recipe_id': null,
        'rating': rating,
        'comments': comments,
      };

      await supabase.from('feedback').insert(insert);

      state = state.copyWith(
        feedbackSubmitted: true,
        response: "✅ Feedback submitted, thank you!",
        messages: [
          ...state.messages,
          ChatMessage(role: "assistant", text: "✅ Thanks for your feedback!"),
        ],
      );
    } catch (e) {
      state = state.copyWith(response: "Feedback error: $e");
      print("submitFeedback error: $e");
    }
  }

  /// Reset conversation
  void resetConversation() {
    state = const VoiceAssistantState();
  }
}