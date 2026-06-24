import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/chat_service.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';
import '../../l10n/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _inbox = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    final inbox = await ChatService.getInbox();
    if (mounted) {
      setState(() {
        _inbox = inbox;
        _loading = false;
      });
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (now.difference(date).inDays == 0 && now.day == date.day) {
        return DateFormat.jm().format(date.toLocal());
      }
      return DateFormat('MMM d').format(date.toLocal());
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _loadInbox),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInbox,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _inbox.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                          child: Text(LocaleKeys.noMessagesYet.tr(),
                              style: const TextStyle(
                                  color: AppColors.textMedium, fontSize: 16))),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _inbox.length,
                    itemBuilder: (context, index) {
                      final item = _inbox[index];
                      final user = item['user'] ?? {};
                      final job = item['job'] ?? {};
                      final latest = item['latestMessage'] ?? {};
                      final unread = item['unreadCount'] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          context
                              .push('/chat/${job['_id']}/${user['_id']}')
                              .then((_) => _loadInbox());
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                backgroundImage:
                                    (user['profileImage'] != null &&
                                            user['profileImage']
                                                .toString()
                                                .isNotEmpty)
                                        ? NetworkImage(user['profileImage'])
                                        : null,
                                child: (user['profileImage'] == null ||
                                        user['profileImage'].toString().isEmpty)
                                    ? Text(
                                        (user['name'] ?? '?')[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18))
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user['name'] ?? 'Unknown User',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (latest['createdAt'] != null)
                                          Text(_formatTime(latest['createdAt']),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textMedium)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(job['title'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            latest['text'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: unread > 0
                                                  ? AppColors.textDark
                                                  : AppColors.textMedium,
                                              fontWeight: unread > 0
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (unread > 0)
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle),
                                            child: Text('$unread',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
