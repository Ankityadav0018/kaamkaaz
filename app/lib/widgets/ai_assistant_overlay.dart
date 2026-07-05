import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/ai_assistant_service.dart';
import '../utils/app_colors.dart';
import 'voice_text_field.dart';

class AIAssistantOverlay extends ConsumerStatefulWidget {
  final String currentRoute;
  const AIAssistantOverlay({super.key, required this.currentRoute});

  static void show(BuildContext context, String route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AIAssistantOverlay(currentRoute: route),
      ),
    );
  }

  @override
  ConsumerState<AIAssistantOverlay> createState() => _AIAssistantOverlayState();
}

class _AIAssistantOverlayState extends ConsumerState<AIAssistantOverlay> {
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    
    final locale = context.locale.languageCode;
    ref.read(aiAssistantProvider.notifier).sendMessage(text, widget.currentRoute, locale);
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('aiAssistantTitle'.tr(),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      Text('aiHowCanIHelp'.tr(),
                          style: TextStyle(fontSize: 12, color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    ref.read(aiAssistantProvider.notifier).stopSpeaking();
                    context.pop();
                  },
                ),
              ],
            ),
          ),
          
          // Chat Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (state.isLoading)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        CircularProgressIndicator(color: cs.primary),
                        const SizedBox(height: 16),
                        Text('aiThinking'.tr(), style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6))),
                      ],
                    ),
                  )
                else if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                        const SizedBox(width: 12),
                        Expanded(child: Text(state.error!, style: const TextStyle(color: AppColors.danger))),
                      ],
                    ),
                  )
                else if (state.responseText != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.responseText!,
                          style: TextStyle(
                            fontSize: 16, 
                            height: 1.5,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                if (state.isSpeaking) {
                                  ref.read(aiAssistantProvider.notifier).stopSpeaking();
                                } else {
                                  final locale = context.locale.languageCode;
                                  ref.read(aiAssistantProvider.notifier).readAloud(state.responseText!, locale);
                                }
                              },
                              icon: Icon(state.isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                              label: Text(state.isSpeaking ? 'aiStopReading'.tr() : 'aiReadAloud'.tr()),
                              style: TextButton.styleFrom(
                                foregroundColor: cs.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                backgroundColor: cs.primary.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(Icons.mic_none_rounded, size: 64, color: theme.dividerColor),
                          const SizedBox(height: 16),
                          Text('aiTypeMessage'.tr(), style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: VoiceTextField(
                    showMic: true,
                    controller: _msgCtrl,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'aiTypeMessage'.tr(),
                      filled: true,
                      fillColor: (isDark ? Colors.white : theme.primaryColorDark).withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
