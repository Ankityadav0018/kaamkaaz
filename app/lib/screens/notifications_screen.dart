import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import '../l10n/locale_keys.g.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final user = ref.watch(authProvider).user;
    final bool isAdmin = user?.role == 'admin';

    // Sort notifications if admin: show unread tasks first
    final notificationsList = List<NotificationModel>.from(state.notifications);
    if (isAdmin) {
      final taskTypes = {
        'kyc_pending',
        'driver_kyc_pending',
        'recruiter_pending',
        'recruiter_onboarding_pending',
        'skill_badge_pending',
        'dispute_pending',
        'withdrawal_pending',
      };
      notificationsList.sort((a, b) {
        final bool aIsTask = !a.isRead && taskTypes.contains(a.type);
        final bool bIsTask = !b.isRead && taskTypes.contains(b.type);

        if (aIsTask && !bIsTask) return -1;
        if (!aIsTask && bIsTask) return 1;

        return b.createdAt.compareTo(a.createdAt);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.notifications.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop()),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
              child: Text(LocaleKeys.markAllRead.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(notificationProvider.notifier).fetchNotifications(),
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : notificationsList.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_none_rounded,
                                size: 56, color: AppColors.textLight),
                            const SizedBox(height: 12),
                            Text(LocaleKeys.noNotifications.tr(),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(LocaleKeys.updatesAppearHere.tr(),
                                style: const TextStyle(
                                    color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: notificationsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _NotifCard(notif: notificationsList[i]),
                  ),
      ),
    );
  }
}

class _NotifCard extends ConsumerWidget {
  final NotificationModel notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color color;
    switch (notif.type) {
      case 'job_posted':
        icon = Icons.work_rounded;
        color = AppColors.primary;
        break;
      case 'job_application':
        icon = Icons.person_add_rounded;
        color = AppColors.info;
        break;
      case 'application_accepted':
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        break;
      case 'application_rejected':
        icon = Icons.cancel_rounded;
        color = AppColors.danger;
        break;
      case 'kyc_approved':
        icon = Icons.verified_rounded;
        color = AppColors.success;
        break;
      case 'kyc_rejected':
        icon = Icons.gpp_bad_rounded;
        color = AppColors.danger;
        break;
      case 'kyc_pending':
        icon = Icons.assignment_late_rounded;
        color = AppColors.warning;
        break;
      case 'driver_kyc_pending':
        icon = Icons.directions_car_rounded;
        color = AppColors.driving;
        break;
      case 'recruiter_pending':
      case 'recruiter_onboarding_pending':
        icon = Icons.business_rounded;
        color = AppColors.primary;
        break;
      case 'skill_badge_pending':
        icon = Icons.verified_user_rounded;
        color = AppColors.success;
        break;
      case 'dispute_pending':
        icon = Icons.gavel_rounded;
        color = AppColors.danger;
        break;
      case 'bug_report':
        icon = Icons.bug_report_rounded;
        color = AppColors.danger;
        break;
      case 'withdrawal_pending':
        icon = Icons.account_balance_wallet_rounded;
        color = AppColors.primary;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppColors.textMedium;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) {
          ref.read(notificationProvider.notifier).markAsRead(notif.id);
        }
        if (notif.relatedId != null && notif.relatedId!.isNotEmpty) {
          final userRole = ref.read(authProvider).user?.role;
          if (userRole == 'admin') {
            if (notif.type == 'kyc_pending') {
              context.push('/admin/kyc-pending');
            } else if (notif.type == 'driver_kyc_pending') {
              context.push('/admin/driver-kyc');
            } else if (notif.type == 'recruiter_pending' ||
                notif.type == 'recruiter_onboarding_pending') {
              context.push('/admin/recruiters');
            } else if (notif.type == 'skill_badge_pending') {
              context.push('/admin/skill-badges');
            } else if (notif.type == 'dispute_pending') {
              context.push('/admin/disputes');
            } else if (notif.type == 'withdrawal_pending') {
              context.push('/admin/withdrawals');
            }
          } else {
            if (notif.type == 'job_posted' ||
                notif.type == 'application_accepted' ||
                notif.type == 'application_rejected') {
              if (userRole == 'worker') {
                context.push('/worker/job/${notif.relatedId}');
              }
            } else if (notif.type == 'job_application') {
              if (userRole == 'recruiter') {
                context.push('/recruiter/applicants/${notif.relatedId}');
              }
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
          border: notif.isRead
              ? null
              : Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title,
                            style: TextStyle(
                              fontWeight:
                                  notif.isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14,
                            )),
                      ),
                      if (ref.watch(authProvider).user?.role == 'admin' &&
                          !notif.isRead &&
                          {
                            'kyc_pending',
                            'driver_kyc_pending',
                            'recruiter_pending',
                            'recruiter_onboarding_pending',
                            'skill_badge_pending',
                            'dispute_pending',
                            'withdrawal_pending',
                          }.contains(notif.type))
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.3),
                                width: 0.8),
                          ),
                          child: const Text(
                            'Action Task',
                            style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(notif.message,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd MMM, hh:mm a').format(notif.createdAt.toLocal()),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textLight)),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
