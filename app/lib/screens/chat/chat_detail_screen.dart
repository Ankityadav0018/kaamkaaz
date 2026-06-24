import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:translator/translator.dart';
import 'package:record/record.dart' as record_pkg;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/socket_service.dart';
import '../../services/secure_upload_service.dart';
import '../../utils/app_colors.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String otherUserId;
  final bool isGroup;

  const ChatDetailScreen({
    super.key,
    required this.jobId,
    required this.otherUserId,
    this.isGroup = false,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _translator = GoogleTranslator();
  final _audioPlayer = AudioPlayer();
  late final record_pkg.AudioRecorder _audioRecorder;
  
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _isRecording = false;
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;
  late RealtimeChannel _supabaseChannel;

  @override
  void initState() {
    super.initState();
    _audioRecorder = record_pkg.AudioRecorder();
    _loadHistory();

    // Supabase Realtime Setup
    final channelName = widget.isGroup ? 'group_chat_${widget.jobId}' : 'chat_${widget.jobId}_${widget.otherUserId}';
    _supabaseChannel = Supabase.instance.client.channel(channelName);
    
    _supabaseChannel.onBroadcast(event: 'new_message', callback: (payload) {
      if (mounted) {
        _handleIncomingRealtimeMessage(payload);
      }
    }).subscribe();

    SocketService().socket?.on('receive_message', _onSocketMessage);
    SocketService().socket?.on('message_sent', _onMessageSent);
  }

  void _handleIncomingRealtimeMessage(Map<String, dynamic> payload) async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null || payload['senderId'] == currentUser.id) return;
    
    // Auto translate if text is present
    if (payload['text'] != null && payload['text'].toString().isNotEmpty) {
       final userLang = context.locale.languageCode;
       if (userLang != 'en') {
          try {
             var translation = await _translator.translate(payload['text'], to: userLang);
             payload['text'] = translation.text;
          } catch(e) {
             // fallback to original
          }
       }
    }
    
    setState(() {
      _messages.insert(0, payload);
    });
  }

  @override
  void dispose() {
    SocketService().socket?.off('receive_message', _onSocketMessage);
    SocketService().socket?.off('message_sent', _onMessageSent);
    _supabaseChannel.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onSocketMessage(data) {
    if (mounted && data['jobId'] == widget.jobId && (data['senderId'] == widget.otherUserId || data['receiverId'] == widget.otherUserId)) {
      // Handled by supabase, but keep for fallback
      if (!_messages.any((m) => m['_id'] == data['_id'] || m['createdAt'] == data['createdAt'])) {
         setState(() => _messages.insert(0, data));
      }
    }
  }

  void _onMessageSent(data) {
    if (mounted && data['jobId'] == widget.jobId) {
      setState(() {
        final idx = _messages.indexWhere((m) => m['tempId'] == data['tempId'] || m['text'] == data['text']);
        if (idx != -1) {
          _messages[idx] = data;
          _messages[idx]['status'] = 'sent';
        } else {
          data['status'] = 'sent';
          _messages.insert(0, data);
        }
      });
    }
  }

  Future<void> _loadHistory() async {
    final history = await ChatService.getChatHistory(widget.jobId, widget.otherUserId);
    final userLang = context.locale.languageCode;

    // Auto-translate recent messages
    if (userLang != 'en') {
      for (var msg in history.take(15)) {
        if (msg['text'] != null && msg['text'].toString().isNotEmpty && msg['senderId'] != ref.read(authProvider).user?.id) {
          try {
            var trans = await _translator.translate(msg['text'], to: userLang);
            msg['text'] = trans.text;
          } catch (_) {}
        }
      }
    }

    if (mounted) {
      setState(() {
        _messages = history.reversed.toList();
        for (var m in _messages) {
          m['status'] = 'read';
        }
        _loading = false;
      });
    }
  }

  void _sendMessage({String? text, String? audioUrl}) {
    if ((text == null || text.isEmpty) && audioUrl == null) return;

    final user = ref.read(authProvider).user;
    if (user == null) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final msgPayload = {
      'jobId': widget.jobId,
      'senderId': user.id,
      'receiverId': widget.isGroup ? 'group' : widget.otherUserId,
      'text': text,
      'audioUrl': audioUrl,
      'tempId': tempId,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'sending',
    };

    setState(() => _messages.insert(0, msgPayload));
    
    // Broadcast via Supabase Realtime
    _supabaseChannel.sendBroadcastMessage(event: 'new_message', payload: msgPayload);

    // Save to DB via Socket
    SocketService().socket?.emit('send_message', msgPayload);

    _messageController.clear();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        // Optimistic UI or show uploading toast
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocaleKeys.uploadingVoiceMessage.tr())));
        final res = await SecureUploadService.uploadImage(filePath: path, uploadType: 'chat_audio');
        if (res['success'] == true) {
           _sendMessage(audioUrl: res['url']);
        }
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const record_pkg.RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _playAudio(String url) async {
    if (_currentlyPlayingUrl == url && _isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _currentlyPlayingUrl = url;
        _isPlaying = true;
      });
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _isPlaying = false);
      });
    }
  }

  String _formatTime(String dateStr) {
    try {
      return DateFormat.jm().format(DateTime.parse(dateStr).toLocal());
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final currentUserId = currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isGroup ? 'groupChatTooltip'.tr() : 'chat'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (widget.isGroup)
             IconButton(icon: const Icon(Icons.group_rounded), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['senderId'] == currentUserId;
                      final hasAudio = msg['audioUrl'] != null && msg['audioUrl'].toString().isNotEmpty;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: [if (!isMe) ...AppColors.softShadow],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (hasAudio)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _currentlyPlayingUrl == msg['audioUrl'] && _isPlaying 
                                          ? Icons.pause_circle_filled_rounded 
                                          : Icons.play_circle_fill_rounded,
                                        color: isMe ? Colors.white : AppColors.primary,
                                        size: 32,
                                      ),
                                      onPressed: () => _playAudio(msg['audioUrl']),
                                    ),
                                    Text(LocaleKeys.voiceMessage.tr(), style: TextStyle(color: isMe ? Colors.white : AppColors.textDark, fontSize: 13, fontStyle: FontStyle.italic)),
                                  ],
                                )
                              else
                                Text(
                                  msg['text'] ?? '',
                                  style: TextStyle(color: isMe ? Colors.white : AppColors.textDark, fontSize: 15),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(msg['createdAt'] ?? ''),
                                    style: TextStyle(color: isMe ? Colors.white70 : AppColors.textLight, fontSize: 10),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      msg['status'] == 'read' ? Icons.done_all : msg['status'] == 'sent' ? Icons.check : Icons.access_time,
                                      size: 12,
                                      color: msg['status'] == 'read' ? Colors.blue[200] : Colors.white70,
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: VoiceTextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'typeAMessage'.tr(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      filled: true,
                      fillColor: AppColors.inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isRecording ? 54 : 48,
                    height: _isRecording ? 54 : 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.grey[200],
                      boxShadow: _isRecording 
                        ? [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 2)] 
                        : [],
                    ),
                    child: Center(
                      child: Icon(Icons.mic_rounded, color: _isRecording ? Colors.white : AppColors.primary, size: _isRecording ? 28 : 24),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () => _sendMessage(text: _messageController.text.trim()),
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
