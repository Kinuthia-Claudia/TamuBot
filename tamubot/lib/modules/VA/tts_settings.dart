// lib/widgets/tts_settings_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/VA/tts_settings.dart';
import 'package:tamubot/modules/VA/assistant_provider.dart';

class TtsSettingsPanel extends ConsumerWidget {
  final VoidCallback onClose;
  final VoidCallback onStopSpeech;

  const TtsSettingsPanel({
    super.key,
    required this.onClose,
    required this.onStopSpeech,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttsSettings = ref.watch(ttsSettingsProvider);

    return Card(
      elevation: 8,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Voice Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // TTS Enabled Toggle
            Row(
              children: [
                const Text('Enable Voice'),
                const Spacer(),
                Switch(
                  value: ttsSettings.enabled,
                  onChanged: (value) {
                    ref.read(ttsSettingsProvider.notifier).toggleEnabled();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Speech Rate
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speech Rate: ${ttsSettings.speechRate.toStringAsFixed(1)}',
                ),
                Slider(
                  value: ttsSettings.speechRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (value) {
                    ref.read(ttsSettingsProvider.notifier).setSpeechRate(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pitch
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pitch: ${ttsSettings.pitch.toStringAsFixed(1)}'),
                Slider(
                  value: ttsSettings.pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: (value) {
                    ref.read(ttsSettingsProvider.notifier).setPitch(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Volume
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Volume: ${(ttsSettings.volume * 100).toInt()}%'),
                Slider(
                  value: ttsSettings.volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) {
                    ref.read(ttsSettingsProvider.notifier).setVolume(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stop Speech Button
            // In tts_settings_panel.dart - update the stop button:

            // Stop/Play Speech Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final ttsService = ref.read(ttsServiceProvider);
                  if (ttsService.isPlaying) {
                    onStopSpeech();
                  } else if (ref
                          .read(assistantProvider)
                          .value
                          ?.messages
                          .isNotEmpty ==
                      true) {
                    // Play the last assistant message
                    final messages = ref
                        .read(assistantProvider)
                        .value!
                        .messages;
                    final lastAssistantMessage = messages.lastWhere(
                      (msg) => !msg.isUser,
                      orElse: () => messages.last,
                    );
                    ref
                        .read(assistantProvider.notifier)
                        .toggleSpeech(lastAssistantMessage);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ref.watch(ttsServiceProvider).isPlaying
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  foregroundColor: ref.watch(ttsServiceProvider).isPlaying
                      ? Colors.red
                      : Colors.blue,
                ),
                child: Text(
                  ref.watch(ttsServiceProvider).isPlaying
                      ? 'Stop Speech'
                      : 'Play Last Message',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
