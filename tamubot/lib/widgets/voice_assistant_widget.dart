import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../providers/voice_assistant_provider.dart';

class VoiceAssistantWidget extends ConsumerWidget {
  const VoiceAssistantWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceAssistantProvider);
    final notifier = ref.read(voiceAssistantProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Waveform
          SizedBox(
            height: 100,
            child: AudioWaveforms(
              enableGesture: false,
              size: const Size(double.infinity, 100),
              recorderController: notifier.recorderController,
              waveStyle: const WaveStyle(
                waveColor: Colors.brown,
                extendWaveform: true,
                showMiddleLine: false,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Record Button
          FloatingActionButton(
            backgroundColor: voiceState.isRecording ? Colors.red : Colors.brown,
            onPressed: () async {
              if (voiceState.isRecording) {
                await notifier.stopRecording();
              } else {
                await notifier.startRecording();
              }
            },
            child: Icon(
              voiceState.isRecording ? Icons.stop : Icons.mic,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),

          // Chat Button
          ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text("Ask Chat"),
            onPressed: () async {
              await notifier.sendChat("Hello!");
            },
          ),
          const SizedBox(height: 20),

          // Output
          if (voiceState.isProcessing)
            const CircularProgressIndicator()
          else ...[
            Text(
              "🗣️ ${voiceState.transcription}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "🤖 ${voiceState.response}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.brown),
            ),
          ],
        ],
      ),
    );
  }
}
