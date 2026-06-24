import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/job_filter_provider.dart';
import '../utils/app_colors.dart';
import '../l10n/locale_keys.g.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class JobSearchBar extends ConsumerStatefulWidget {
  final VoidCallback onFilterTap;
  final int activeFiltersCount;

  const JobSearchBar({
    super.key,
    required this.onFilterTap,
    required this.activeFiltersCount,
  });

  @override
  ConsumerState<JobSearchBar> createState() => _JobSearchBarState();
}

class _JobSearchBarState extends ConsumerState<JobSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(jobFilterProvider).keyword ?? '';
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(jobFilterProvider.notifier).setKeyword(query);
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        // Use currently active locale from context or default to Hindi/English mix
        final localeId = context.locale.languageCode == 'hi' ? 'hi_IN' : 'en_US';
        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                 _onSearchChanged(_controller.text);
              }
            });
          },
          localeId: localeId,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(jobFilterProvider);

    // Sync controller if keyword is cleared externally
    if (filters.keyword == null && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Center(
                  child: VoiceTextField(
                    controller: _controller,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: LocaleKeys.searchPlaceholder.tr(),
                      hintStyle:
                          const TextStyle(color: AppColors.textLight, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.primary),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _listen,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: EdgeInsets.all(_isListening ? 6 : 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? Colors.red : AppColors.primary,
                                size: _isListening ? 26 : 24,
                              ),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () {
                                _controller.clear();
                                ref.read(jobFilterProvider.notifier).setKeyword(null);
                              },
                            ),
                        ],
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: widget.activeFiltersCount > 0
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: widget.activeFiltersCount > 0
                          ? Colors.white
                          : AppColors.primary,
                    ),
                  ),
                  if (widget.activeFiltersCount > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.activeFiltersCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
