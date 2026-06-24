import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voice_input_service.dart';
import '../utils/app_colors.dart';

class ListeningOverlay extends ConsumerStatefulWidget {
  const ListeningOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ListeningOverlay(),
    );
  }

  @override
  ConsumerState<ListeningOverlay> createState() => _ListeningOverlayState();
}

class _ListeningOverlayState extends ConsumerState<ListeningOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputProvider);

    // Auto close when listening stops
    ref.listen<VoiceInputState>(voiceInputProvider, (previous, next) {
      if (previous?.isListening == true && !next.isListening) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          )
        ]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'listeningSpeakNow'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final value = (_controller.value - delay).abs();
                    final height = 20 + (30 * (1 - value).clamp(0.0, 1.0));
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 6,
                      height: height,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(
              voiceState.recognizedText.isEmpty 
                  ? '...' 
                  : voiceState.recognizedText,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              onPressed: () {
                ref.read(voiceInputProvider.notifier).stopListening();
              },
              child: const Icon(Icons.stop, color: Colors.white, size: 32),
            )
          ],
        ),
      ),
    );
  }
}
