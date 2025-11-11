import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:tamubot/widgets/chat_bubble.dart';
import 'package:tamubot/providers/voice_assistant_provider.dart';

class VoiceAssistantWidget extends ConsumerStatefulWidget {
  const VoiceAssistantWidget({super.key});

  @override
  ConsumerState<VoiceAssistantWidget> createState() =>
      _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends ConsumerState<VoiceAssistantWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    ref.read(voiceAssistantProvider.notifier).initTts();
  }

  // Show recording options dialog
  void _showRecordingOptionsDialog(BuildContext context, VoiceAssistantNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audiotrack, size: 48, color: Colors.brown),
            const SizedBox(height: 16),
            const Text(
              "Recording Complete",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("What would you like to do with your recording?"),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      notifier.discardRecording();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text("Delete", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      notifier.sendRecordedAudio();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Send", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                notifier.hideRecordingOptions();
              },
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFeedbackDialog() async {
    final notifier = ref.read(voiceAssistantProvider.notifier);
    final ratingCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Give Feedback"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ratingCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Rating (1-5)"),
              ),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(labelText: "Comments"),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final rating = int.tryParse(ratingCtrl.text.trim()) ?? 0;
                final comment = commentCtrl.text.trim();
                if (rating >= 1 && rating <= 5 && comment.isNotEmpty) {
                  await notifier.submitFeedback(rating, comment);
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputRow(VoiceAssistantState state, VoiceAssistantNotifier notifier) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: AudioWaveforms(
                enableGesture: false,
                size: const Size(48, 48),
                recorderController: notifier.recorderController,
                waveStyle: const WaveStyle(
                  waveColor: Colors.brown,
                  extendWaveform: true,
                  showMiddleLine: false,
                ),
              ),
            ),
            IconButton(
              icon: Icon(state.isRecording ? Icons.stop_circle : Icons.mic),
              color: state.isRecording ? Colors.red : Colors.deepOrange,
              onPressed: () async {
                if (state.isRecording) {
                  await notifier.stopRecording();
                } else {
                  await notifier.startRecording();
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: state.isRecording
                      ? "Listening..."
                      : "Type a message...",
                  border: InputBorder.none,
                ),
                onSubmitted: (value) async {
                  final v = value.trim();
                  if (v.isNotEmpty) {
                    await notifier.sendChat(v);
                    _textController.clear();
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.deepOrange),
              onPressed: () async {
                final v = _textController.text.trim();
                if (v.isNotEmpty) {
                  await notifier.sendChat(v);
                  _textController.clear();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.feedback_outlined,
                  color: Colors.deepOrange),
              onPressed: _showFeedbackDialog,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceAssistantProvider);
    final notifier = ref.read(voiceAssistantProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Show recording options when needed
    if (state.showRecordingOptions) {
      WidgetsBinding.instance.addPostFrameCallback((_) { 
        _showRecordingOptionsDialog(context, notifier);
      });
    }

    return Column(
      children: [
        // Chat history
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.messages.length,
              itemBuilder: (context, i) {
                final m = state.messages[i];
                return ChatBubble(message: m.text, isUser: m.role == "user");
              },
            ),
          ),
        ),

        if (state.isProcessing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(),
          ),

        const Divider(height: 1),

        // Bottom input row
        _buildInputRow(state, notifier),

        if (state.feedbackSubmitted)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              state.response ?? "Feedback submitted",
              style: const TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }
}