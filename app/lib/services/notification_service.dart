import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/notification_model.dart';
import 'api_service.dart';
import '../utils/api_config.dart';
import '../utils/app_keys.dart';
import 'package:easy_localization/easy_localization.dart';
import '../l10n/locale_keys.g.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  if (message.data['type'] == 'urgent_job') {
    await NotificationService._showLocalNotification(
      title: message.data['title'] ?? 'Urgent Alert',
      body: message.data['message'] ?? 'You have a new urgent job alert.',
      payload: json.encode(message.data),
    );
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // Configure Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'kaamkaaz_notifications',
        'Kaamkaaz Alerts',
        description: 'Important notifications from Kaamkaaz',
        importance: Importance.high,
        playSound: true,
      );

      const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
        'urgent_alerts',
        'Urgent Job Alerts',
        description: 'Critical notifications for urgent job postings',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(urgentChannel);

      // Initialize timezone for scheduled notifications
      tz.initializeTimeZones();
      final currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));

      // Initialize Local Notifications
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null) {
            final data = json.decode(details.payload!);
            _handleNotificationClick(data);
          }
        },
      );

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint("NotificationService initialization failed: $e");
    }
  }

  static Future<void> setupFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get token
        String? token = await messaging.getToken();
        if (token != null) {
          debugPrint("FCM Token: $token");
          await updateFcmToken(token);
        }

        // Listen for token updates
        messaging.onTokenRefresh.listen((newToken) {
          updateFcmToken(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.data['type'] == 'urgent_job') {
            final context = AppKeys.rootNavigatorKey.currentContext;
            if (context != null) {
              context.push('/urgent-alert', extra: {
                'title': message.notification?.title ?? message.data['title'] ?? 'Urgent Alert',
                'body': message.notification?.body ?? message.data['message'] ?? 'You have a new urgent job alert.',
                'jobId': message.data['relatedId'],
              });
              return;
            }
          }

          if (message.notification != null) {
            _showLocalNotification(
              title: message.notification!.title ?? '',
              body: message.notification!.body ?? '',
              payload: json.encode(message.data),
            );
          }
        });

        // Handle app opened from terminated state
        RemoteMessage? initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationClick(initialMessage.data);
        }

        // Handle app opened from background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationClick(message.data);
        });
      }
    } catch (e) {
      debugPrint("FCM setup failed: $e");
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    final Map<String, dynamic> data = json.decode(payload);
    final isUrgent = data['type'] == 'urgent_job';

    final androidDetails = AndroidNotificationDetails(
      isUrgent ? 'urgent_alerts' : 'kaamkaaz_notifications',
      isUrgent ? 'Urgent Job Alerts' : 'Kaamkaaz Alerts',
      importance: isUrgent ? Importance.max : Importance.high,
      priority: isUrgent ? Priority.max : Priority.high,
      fullScreenIntent: isUrgent,
      enableVibration: true,
    );
    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      interruptionLevel: isUrgent ? InterruptionLevel.critical : InterruptionLevel.active,
    );
    
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  static Future<void> updateFcmToken(String token) async {
    try {
      await ApiService.post(ApiConfig.updateFcmToken, {'fcmToken': token});
    } catch (e) {
      return;
    }
  }

  // --- Smart Notification Features ---

  static Future<void> subscribeToJobCategory(String category) async {
    await FirebaseMessaging.instance.subscribeToTopic('category_${category.replaceAll(' ', '_').toLowerCase()}');
  }

  static Future<void> unsubscribeFromJobCategory(String category) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic('category_${category.replaceAll(' ', '_').toLowerCase()}');
  }

  static Future<void> triggerApplicationStatusLocal(String title, String body, {String? relatedId}) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: json.encode({'type': 'application_status', 'relatedId': relatedId}),
    );
  }

  static Future<void> scheduleJobReminder(String jobId, String jobTitle, String location, DateTime jobDateTime) async {
    final eveningBefore = tz.TZDateTime.local(
      jobDateTime.year, jobDateTime.month, jobDateTime.day - 1, 18, 0, 0
    );
    
    if (eveningBefore.isAfter(tz.TZDateTime.now(tz.local))) {
      await _localNotifications.zonedSchedule(
        id: jobId.hashCode,
        title: LocaleKeys.reminderJobTomorrow.tr(),
        body: LocaleKeys.jobTomorrowBody.tr(namedArgs: {'jobTitle': jobTitle, 'location': location}),
        scheduledDate: eveningBefore,
        notificationDetails: NotificationDetails(android: AndroidNotificationDetails('kaamkaaz_notifications', 'Kaamkaaz Alerts')),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: json.encode({'type': 'reminder', 'relatedId': jobId}),
      );
    }

    final morningOf = tz.TZDateTime.local(
      jobDateTime.year, jobDateTime.month, jobDateTime.day, 7, 0, 0
    );
    
    if (morningOf.isAfter(tz.TZDateTime.now(tz.local))) {
      await _localNotifications.zonedSchedule(
        id: jobId.hashCode + 1,
        title: LocaleKeys.jobToday.tr(),
        body: LocaleKeys.jobTodayBody.tr(namedArgs: {'jobTitle': jobTitle}),
        scheduledDate: morningOf,
        notificationDetails: NotificationDetails(android: AndroidNotificationDetails('kaamkaaz_notifications', 'Kaamkaaz Alerts')),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: json.encode({'type': 'reminder', 'relatedId': jobId}),
      );
    }
    
    // Follow-up reminder if not checked in (30 mins after start)
    final followUp = tz.TZDateTime.from(jobDateTime.add(const Duration(minutes: 30)), tz.local);
    if (followUp.isAfter(tz.TZDateTime.now(tz.local))) {
      await _localNotifications.zonedSchedule(
        id: jobId.hashCode + 2,
        title: LocaleKeys.checkInReminder.tr(),
        body: LocaleKeys.checkInBody.tr(namedArgs: {'jobTitle': jobTitle}),
        scheduledDate: followUp,
        notificationDetails: NotificationDetails(android: AndroidNotificationDetails('kaamkaaz_notifications', 'Kaamkaaz Alerts')),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: json.encode({'type': 'check_in_reminder', 'relatedId': jobId}),
      );
    }
  }

  static Future<void> cancelJobReminders(String jobId) async {
    await _localNotifications.cancel(id: jobId.hashCode);
    await _localNotifications.cancel(id: jobId.hashCode + 1);
    await _localNotifications.cancel(id: jobId.hashCode + 2);
  }

  // ------------------------------------

  static void _handleNotificationClick(Map<String, dynamic> data) {
    final context = AppKeys.rootNavigatorKey.currentContext;
    if (context == null) return;

    final String? type = data['type'];
    final String? relatedId = data['relatedId'];

    switch (type) {
      case 'new_application':
        if (relatedId != null) context.push('/recruiter/applicants/$relatedId');
        break;
      case 'application_accepted':
      case 'application_rejected':
        context.push('/worker/my-jobs');
        break;
      case 'new_job':
        context.push('/worker');
        break;
      case 'urgent_job':
        context.push('/urgent-alert', extra: {
          'title': data['title'] ?? 'Urgent Alert',
          'body': data['message'] ?? 'You have a new urgent job alert.',
          'jobId': relatedId,
        });
        break;
      case 'kyc_approved':
      case 'kyc_rejected':
        context.push('/worker/profile');
        break;
      case 'chat':
        if (relatedId != null && data['senderId'] != null) {
          context
              .push('/chat/${data['jobId'] ?? relatedId}/${data['senderId']}');
        } else {
          context.push('/chat');
        }
        break;
      default:
        context.push('/notifications');
    }
  }

  static Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final res =
        await ApiService.get('${ApiConfig.notifications}?page=$page&limit=30');
    if (res['success'] == true && res['data'] != null) {
      return {
        'success': true,
        'data': (res['data'] as List)
            .map((n) => NotificationModel.fromJson(n))
            .toList(),
        'unreadCount': res['unreadCount'] ?? 0,
      };
    }
    return {'success': false, 'data': [], 'unreadCount': 0};
  }

  static Future<void> markAllRead() async {
    await ApiService.put(ApiConfig.markAllRead, {});
  }

  static Future<void> markRead(String id) async {
    await ApiService.put('${ApiConfig.notifications}/$id/read', {});
  }
}
