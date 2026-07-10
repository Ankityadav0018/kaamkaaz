import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import 'api_service.dart';
import 'logger_service.dart';

class AIAssistantState {
  final bool isLoading;
  final bool isSpeaking;
  final String? responseText;
  final String? error;

  AIAssistantState({
    this.isLoading = false,
    this.isSpeaking = false,
    this.responseText,
    this.error,
  });

  AIAssistantState copyWith({
    bool? isLoading,
    bool? isSpeaking,
    String? responseText,
    String? error,
  }) {
    return AIAssistantState(
      isLoading: isLoading ?? this.isLoading,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      responseText: responseText ?? this.responseText,
      error: error,
    );
  }
}

class AIAssistantNotifier extends StateNotifier<AIAssistantState> {
  final Ref ref;
  FlutterTts? _tts;
  
  // Keep track of the stateless history to pass to the backend
  final List<Map<String, String>> _chatHistory = [];
  
  static const _historyKey = 'kaamkaaz_ai_chat_history';

  AIAssistantNotifier(this.ref) : super(AIAssistantState()) {
    _initTTS();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        for (var item in decoded) {
          _chatHistory.add({
            'role': item['role'] as String,
            'text': item['text'] as String,
          });
        }
      }
    } catch (e) {
      LoggerService.e('Failed to load AI chat history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = json.encode(_chatHistory);
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      LoggerService.e('Failed to save AI chat history: $e');
    }
  }

  Future<void> clearHistory() async {
    _chatHistory.clear();
    await _saveHistory();
    state = state.copyWith(responseText: null, error: null);
  }

  Future<void> _initTTS() async {
    _tts = FlutterTts();
    await _tts?.setLanguage("hi-IN"); // Set default language to Hindi to start

    try {
      List<dynamic> voices = await _tts!.getVoices;
      for (var v in voices) {
        if (v is Map) {
          String name = v['name']?.toString().toLowerCase() ?? '';
          String locale = v['locale']?.toString().toLowerCase() ?? '';
          
          // Look for male Hindi or Indian English voices
          if (locale.contains('hi') || locale.contains('in')) {
            // Google TTS Male identifiers: -x-hid, -x-hic. iOS: rishi. Or explicit 'male'
            if (name.contains('male') || 
                name.contains('-x-hid') || 
                name.contains('-x-hic') || 
                name.contains('rishi')) {
              await _tts!.setVoice({"name": v["name"], "locale": v["locale"]});
              break;
            }
          }
        }
      }
    } catch (e) {
      print("Voice selection error: $e");
    }

    await _tts?.setPitch(0.8); // Slightly lower pitch to enhance masculinity
    await _tts?.setSpeechRate(0.5); // Robust and steady pacing
    
    _tts?.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
    });
  }

  Future<void> stopSpeaking() async {
    await _tts?.stop();
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> readAloud(String text, String locale) async {
    if (text.isEmpty) return;
    
    // Convert 2-letter language code to TTS compatible format, default to Hindi India if not mapped
    String ttsLocale = 'hi-IN';
    switch (locale) {
      case 'en': ttsLocale = 'en-US'; break;
      case 'ta': ttsLocale = 'ta-IN'; break;
      case 'te': ttsLocale = 'te-IN'; break;
      case 'bn': ttsLocale = 'bn-IN'; break;
      case 'mr': ttsLocale = 'mr-IN'; break;
      case 'gu': ttsLocale = 'gu-IN'; break;
      case 'kn': ttsLocale = 'kn-IN'; break;
      case 'ml': ttsLocale = 'ml-IN'; break;
      case 'pa': ttsLocale = 'pa-IN'; break;
    }
    
    await _tts?.setLanguage(ttsLocale);
    state = state.copyWith(isSpeaking: true);
    await _tts?.speak(text);
  }

  Future<void> sendMessage(String message, String currentRoute, String locale) async {
    if (message.isEmpty) return;
    
    await stopSpeaking();
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final userState = ref.read(authProvider);
      final role = userState.user?.role ?? 'guest';
      final name = userState.user?.name ?? 'Dost';

      final payload = {
        'message': message,
        'locale': locale,
        'currentRoute': currentRoute,
        'role': role,
        'name': name,
        'history': _chatHistory,
      };
      
      final response = await ApiService.post('/ai/assist', payload);
      
      if (response['success'] == true && response['text'] != null) {
        final responseText = response['text'] as String;
        
        // Append to local stateless history
        _chatHistory.add({'role': 'user', 'text': message});
        _chatHistory.add({'role': 'model', 'text': responseText});
        await _saveHistory();
        
        state = state.copyWith(isLoading: false, responseText: responseText);
        
        // Auto read aloud
        await readAloud(responseText, locale);
      } else {
        if (response['errorDetails'] != null) {
          LoggerService.e('AI Error Details: ${response['errorDetails']} \n ${response['stack']}');
        }
        throw response['message'] ?? 'Unknown error';
      }
      
    } catch (e) {
      LoggerService.e('AI Error: $e');
      state = state.copyWith(isLoading: false, error: 'aiError'.tr());
    }
  }
}

final aiAssistantProvider = StateNotifierProvider<AIAssistantNotifier, AIAssistantState>((ref) {
  return AIAssistantNotifier(ref);
});
