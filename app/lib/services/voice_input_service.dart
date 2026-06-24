import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';

class VoiceInputState {
  final bool isListening;
  final String recognizedText;
  final String? activeFieldId;
  final bool hasPermission;
  final bool isInitialized;

  VoiceInputState({
    this.isListening = false,
    this.recognizedText = '',
    this.activeFieldId,
    this.hasPermission = false,
    this.isInitialized = false,
  });

  VoiceInputState copyWith({
    bool? isListening,
    String? recognizedText,
    String? activeFieldId,
    bool? hasPermission,
    bool? isInitialized,
  }) {
    return VoiceInputState(
      isListening: isListening ?? this.isListening,
      recognizedText: recognizedText ?? this.recognizedText,
      activeFieldId: activeFieldId ?? this.activeFieldId,
      hasPermission: hasPermission ?? this.hasPermission,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class VoiceInputNotifier extends Notifier<VoiceInputState> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  VoiceInputState build() {
    _initSpeech();
    return VoiceInputState();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      state = state.copyWith(hasPermission: available, isInitialized: true);
    } catch (e) {
      debugPrint("Speech init error: $e");
      state = state.copyWith(hasPermission: false, isInitialized: true);
    }
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      state = state.copyWith(isListening: false);
    }
  }

  void _onError(dynamic error) {
    debugPrint("Speech error: $error");
    state = state.copyWith(isListening: false);
  }

  Future<bool> toggleListening({
    required String fieldId,
    required String localeCode,
    required Function(String, bool) onResult,
  }) async {
    if (state.isListening) {
      _speech.stop();
      state = state.copyWith(isListening: false);
      if (state.activeFieldId == fieldId) {
        return false; // Stopped the current field
      }
    }

    if (!state.hasPermission) {
      bool available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      state = state.copyWith(hasPermission: available);
      if (!available) return false;
    }

    state = state.copyWith(
      isListening: true,
      activeFieldId: fieldId,
      recognizedText: '',
    );

    // Find best matching locale
    String? targetLocale;
    try {
      var locales = await _speech.locales();
      String baseLang = localeCode.split('_').first;
      for (var loc in locales) {
        if (loc.localeId.startsWith(baseLang)) {
          targetLocale = loc.localeId;
          if (loc.localeId == localeCode) break; // Exact match preferred
        }
      }
    } catch (e) {
      debugPrint("Error fetching locales: $e");
    }

    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(recognizedText: result.recognizedWords);
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: targetLocale,
        cancelOnError: true,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    return true;
  }

  void stopListening() {
    _speech.stop();
    state = state.copyWith(isListening: false);
  }
}

final voiceInputProvider = NotifierProvider<VoiceInputNotifier, VoiceInputState>(() {
  return VoiceInputNotifier();
});
