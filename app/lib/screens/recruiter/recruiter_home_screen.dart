import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../services/job_service.dart';
import '../../providers/notification_provider.dart';
import '../../models/job_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/ratings_bottom_sheet.dart';
import '../../l10n/locale_keys.g.dart';
import '../../services/share_service.dart';
import '../../providers/stats_provider.dart';
import '../search_profiles_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'recruiter_applications_screen.dart';
import '../../services/credits_service.dart';
class RecruiterHomeScreen extends ConsumerStatefulWidget {
  const RecruiterHomeScreen({super.key});

  @override
  ConsumerState<RecruiterHomeScreen> createState() =>
      _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends ConsumerState<RecruiterHomeScreen> {
  int _currentIndex = 0;
  String _statusFilter = 'open';
  int _creditsBalance = 0;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _loadData();
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  Future<void> _loadData() async {
    ref.read(jobProvider.notifier).fetchMyJobs(status: _statusFilter);
    try {
      final res = await CreditsService.getCredits();
      if (mounted) {
        setState(() => _creditsBalance = (res['data']?['credits_balance'] as num?)?.toInt() ?? 0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex > 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildJobsPage(),
            const RecruiterApplicationsScreen(),
            RefreshIndicator(
              onRefresh: () async =>
                  ref.read(jobProvider.notifier).fetchMyJobs(),
              child: const SearchProfilesScreen(),
            ),
            RefreshIndicator(
              onRefresh: () async =>
                  ref.read(authProvider.notifier).refreshUser(),
              child: _buildProfilePage(),
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final user = ref.read(authProvider).user;
                  if (user != null) {
                    if (user.isRecruiterSuspended) {
                      context.push('/recruiter/suspended');
                      return;
                    }
                    if (!user.isRecruiterVerified) {
                      context.push('/recruiter/verification-pending');
                      return;
                    }
                  }
                  await context.push('/recruiter/post-job');
                  if (mounted) {
                    ref
                        .read(jobProvider.notifier)
                        .fetchMyJobs(status: _statusFilter);
                  }
                },
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(LocaleKeys.postJob.tr(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              )
            : null,
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() => _currentIndex = i);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textLight,
            backgroundColor: Colors.white,
            elevation: 16,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                    _currentIndex == 0
                        ? Icons.dashboard_rounded
                        : Icons.dashboard_outlined,
                    size: 24),
                label: LocaleKeys.myJobs.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                    _currentIndex == 1
                        ? Icons.description_rounded
                        : Icons.description_outlined,
                    size: 24),
                label: LocaleKeys.applicants.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                    _currentIndex == 2
                        ? Icons.search_rounded
                        : Icons.search_outlined,
                    size: 24),
                label: LocaleKeys.search.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                    _currentIndex == 3
                        ? Icons.person_rounded
                        : Icons.person_outlined,
                    size: 24),
                label: LocaleKeys.profile.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobsPage() {
    final jobState = ref.watch(jobProvider);
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(recruiterStatsProvider);

    return SafeArea(
      child: Column(
        children: [
          // ── Premium Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.95), AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome & Company
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.namaste.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.name.split(' ').first ?? LocaleKeys.recruiter.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Premium Company Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.business_center_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                user?.companyName.isNotEmpty == true ? user!.companyName : LocaleKeys.recruiter.tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  children: [
                    // Chat Button
                    GestureDetector(
                      onTap: () => context.push('/chat'),
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                     // Credits Chip
                    GestureDetector(
                      onTap: () {
                        context.push('/recruiter/credits').then((_) => _loadData());
                      },
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text('$_creditsBalance credits', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Notification Button
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/recruiter/notifications'),
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        if (ref.watch(notificationProvider).unreadCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Removed Overlapping Stats Cards to save space

          // Low Credits Nudge
          if (_creditsBalance < 3)
            Transform.translate(
              offset: const Offset(0, -18),
              child: GestureDetector(
                onTap: () => context.push('/recruiter/credits').then((_) => _loadData()),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Credits low ($_creditsBalance remaining). Buy more to keep posting urgent jobs.',
                          style: TextStyle(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Buy Credits', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
            ),

          // Shortcuts / Feature cards
          Transform.translate(
            offset: const Offset(0, -12),
            child: Container(
              height: 120,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _featureCard(
                        title: LocaleKeys.findDrivers.tr(),
                        subTitle: LocaleKeys.hireVerifiedDrivers.tr(),
                        icon: Icons.drive_eta_rounded,
                        color: AppColors.driving,
                        onTap: () => context.push('/driver/find'),
                      );
                    case 1:
                      return _featureCard(
                        title: LocaleKeys.topRated.tr(),
                        subTitle: LocaleKeys.bestWorkersNearby.tr(),
                        icon: Icons.star_rounded,
                        color: AppColors.accent,
                        onTap: () {
                          setState(() => _currentIndex = 1);
                        },
                      );
                    case 2:
                      return _featureCard(
                        title: LocaleKeys.pastWorkers.tr(),
                        subTitle: LocaleKeys.rehireTrustedWorkers.tr(),
                        icon: Icons.history_rounded,
                        color: Colors.teal,
                        onTap: () => context.push('/recruiter/past-workers'),
                      );
                    default:
                      return const SizedBox();
                  }
                },
              ),
            ),
          ),

          // Status filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: ['open', 'assigned', 'completed'].map((s) {
                final isSelected = _statusFilter == s;
                final color = s == 'open'
                    ? AppColors.success
                    : s == 'assigned'
                        ? AppColors.info
                        : AppColors.textMedium;
                return GestureDetector(
                  onTap: () {
                    setState(() => _statusFilter = s);
                    ref.read(jobProvider.notifier).fetchMyJobs(status: s);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color : AppColors.inputBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s.tr().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected ? Colors.white : AppColors.textMedium,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
          // Jobs list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref
                  .read(jobProvider.notifier)
                  .fetchMyJobs(status: _statusFilter),
              child: jobState.isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : jobState.myJobs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.post_add_rounded,
                                  size: 56, color: AppColors.textLight),
                              const SizedBox(height: 12),
                              Text(LocaleKeys.noJobsPostedYet.tr(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              Text(LocaleKeys.tapPlusToPost.tr(),
                                  style: const TextStyle(
                                      color: AppColors.textLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: jobState.myJobs.length,
                          itemBuilder: (_, i) => _JobCard(
                            job: jobState.myJobs[i],
                            onTap: () => context.push(
                                '/recruiter/applicants/${jobState.myJobs[i].id}'),
                            onComplete: () =>
                                _completeJob(jobState.myJobs[i].id),
                            onDelete: () => _deleteJob(jobState.myJobs[i].id),
                            onEdit: () => context.push('/recruiter/edit-job', extra: jobState.myJobs[i]),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJob(String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.deleteJob.tr()),
        content: Text(LocaleKeys.deleteJobConfirm.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(LocaleKeys.cancel.tr().toUpperCase())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child:
                Text(LocaleKeys.deleteJob.tr().split('?').first.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await JobService.deleteJob(jobId);
      if (res['success'] == true) {
        ref.read(jobProvider.notifier).fetchMyJobs(status: _statusFilter);
        ref.invalidate(recruiterStatsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(LocaleKeys.jobDeletedSuccess.tr()),
            backgroundColor: AppColors.success,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res['message'] ?? 'Failed to delete job'),
            backgroundColor: AppColors.danger,
          ));
        }
      }
    }
  }

  Future<void> _completeJob(String jobId) async {
    final result = await ref
        .read(jobProvider.notifier)
        .updateJobStatus(jobId, 'completed');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor:
            result['success'] == true ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildProfilePage() {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();
    return RefreshIndicator(
      onRefresh: () async => ref.read(authProvider.notifier).refreshUser(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 24),
            if (user.isRecruiterNotSubmitted)
              GestureDetector(
                onTap: () => context.push('/recruiter/onboarding'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete your profile — Fill KYC',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange, size: 14),
                    ],
                  ),
                ),
              ),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: user.profileImage.isNotEmpty
                        ? NetworkImage(user.profileImage)
                        : null,
                    child: user.profileImage.isEmpty
                        ? Text(
                            (user.name.isNotEmpty)
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 40),
                      Text(user.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 20, color: AppColors.primary),
                        onPressed: () =>
                            context.push('/recruiter/profile/edit'),
                      ),
                    ],
                  ),
                  if (user.companyName.isNotEmpty)
                    Text(user.companyName,
                        style: const TextStyle(color: AppColors.textMedium)),
                  Text('+91 ${user.phone}',
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ClipRect(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat(
                        Icons.star_rounded,
                        user.rating.average.toStringAsFixed(1),
                        LocaleKeys.rating.tr(),
                        Colors.amber),
                    _stat(
                        Icons.assignment_rounded,
                        '${ref.watch(jobProvider).myJobs.length}',
                        LocaleKeys.activeJobs.tr(),
                        Colors.blue),
                    _stat(Icons.people_rounded, '${user.rating.count}',
                        LocaleKeys.applicants.tr(), Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _menuTile(context, Icons.star_border_rounded,
                LocaleKeys.viewWorkerFeedback.tr(), () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => RatingsBottomSheet(userId: user.id),
              );
            }),
            _menuTile(context, Icons.edit_rounded, LocaleKeys.editProfile.tr(),
                () => context.push('/recruiter/profile')),
            _menuTile(
                context,
                Icons.confirmation_number_rounded,
                'My Credits',
                () => context.push('/recruiter/credits').then((_) => _loadData())),
            _menuTile(
                context,
                Icons.notifications_rounded,
                LocaleKeys.notifications.tr(),
                () => context.push('/recruiter/notifications')),
            _menuTile(
                context,
                Icons.gavel_rounded,
                LocaleKeys.myDisputes.tr(),
                () => context.push('/disputes/my')),
            _menuTile(
                context,
                Icons.people_alt_rounded,
                LocaleKeys.pastWorkers.tr(),
                () => context.push('/recruiter/past-workers')),
            

            _menuTile(context, Icons.account_balance_wallet_rounded,
                'Wallet (Refer & Earn)', () => context.push('/referral')),
            _menuTile(
                context,
                Icons.translate_rounded,
                LocaleKeys.selectLanguage.tr(),
                () => context.push('/language')),
            _menuTile(
                context,
                Icons.bug_report_rounded,
                LocaleKeys.reportProblem.tr(),
                () => context.push('/report-problem')),
            _menuTile(
                context,
                Icons.lock_rounded,
                'appLockPin'.tr(),
                () => context.push('/set-pin')),
            _menuTile(
                context,
                Icons.lock_reset_rounded,
                LocaleKeys.changePassword.tr(),
                () => context.push('/change-password')),
            
            _menuTile(context, Icons.gavel_outlined, LocaleKeys.legalAndInformation.tr(),
                () async {
              final uri = Uri.parse('https://kaamkaaz.org');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }),

            const SizedBox(height: 16),
            _menuTile(context, Icons.logout_rounded, LocaleKeys.logout.tr(),
                () => ref.read(authProvider.notifier).logout(),
                isRed: true),
            const SizedBox(height: 100), // Spacing for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {bool isRed = false, Widget? trailing}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isRed ? AppColors.danger : AppColors.primary)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: isRed ? AppColors.danger : AppColors.primary, size: 28),
      ),
      title: Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isRed ? AppColors.danger : Colors.black87),
      ),
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded,
              color: isRed ? AppColors.danger : Colors.grey),
      onTap: onTap,
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) =>
      Expanded(
        child: ClipRect(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(
      {required String title,
      required String subTitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0DA)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: -0.2)),
                  Text(subTitle,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _JobCard(
      {required this.job,
      required this.onTap,
      required this.onComplete,
      required this.onDelete,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.getCategoryColor(job.category);
    Color statusColor;
    switch (job.status) {
      case 'open':
        statusColor = AppColors.success;
        break;
      case 'assigned':
        statusColor = AppColors.info;
        break;
      case 'completed':
        statusColor = AppColors.textMedium;
        break;
      default:
        statusColor = AppColors.textLight;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Icon(
                      AppColors.getCategoryIcon(job.category),
                      size: 24,
                      color: catColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(job.status.tr().toUpperCase(),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor)),
                          ),
                          if (job.isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color:
                                      AppColors.danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(LocaleKeys.urgent.tr().toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.danger)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Text(
                    job.formattedWage,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_rounded,
                        size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text('${job.applicantCount} ${LocaleKeys.applicants.tr()}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMedium)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        job.location.address,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMedium),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (job.status == 'assigned')
                  TextButton(
                    onPressed: onComplete,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(LocaleKeys.markComplete.tr(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                if (job.status == 'open') ...[
                  TextButton.icon(
                    onPressed: () => ShareService.shareJobOnWhatsApp(job.id),
                    icon: const Icon(Icons.share_rounded, size: 14),
                    label: Text(LocaleKeys.share.tr(),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                    label: Text(LocaleKeys.editProfile.tr().split(' ')[0], // Using "Edit" from "Edit Profile"
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
                if (job.status == 'open')
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 14),
                    label: Text(LocaleKeys.deleteJob.tr().split('?').first,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      foregroundColor: AppColors.danger,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
