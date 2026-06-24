import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationState(
      {this.notifications = const [],
      this.unreadCount = 0,
      this.isLoading = false});

  NotificationState copyWith(
          {List<NotificationModel>? notifications,
          int? unreadCount,
          bool? isLoading}) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    _initSocket();
  }

  void _initSocket() {
    SocketService().onNotification = (data) {
      final notif = NotificationModel.fromJson(data);
      addNotification(notif);
    };
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    final result = await NotificationService.getNotifications();
    if (result['success'] == true) {
      state = state.copyWith(
        notifications: result['data'],
        unreadCount: result['unreadCount'],
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAllRead() async {
    await NotificationService.markAllRead();
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => NotificationModel.fromJson({
                '_id': n.id,
                'userId': n.userId,
                'title': n.title,
                'message': n.message,
                'type': n.type,
                'isRead': true,
                'createdAt': n.createdAt.toIso8601String(),
              }))
          .toList(),
      unreadCount: 0,
    );
  }

  Future<void> markAsRead(String id) async {
    await NotificationService.markRead(id);
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id && !n.isRead) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            relatedId: n.relatedId,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList(),
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
  }

  void addNotification(NotificationModel n) {
    state = state.copyWith(
      notifications: [n, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    );
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
        (ref) => NotificationNotifier());
