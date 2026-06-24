import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/application_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/offline_banner.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import '../../widgets/job_card.dart';
import 'worker_applications_screen.dart';
import '../search_profiles_screen.dart';
import '../../l10n/locale_keys.g.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/job_filter_provider.dart';
import '../../widgets/job_search_bar.dart';
import '../../utils/constants.dart';
import '../../widgets/job_filter_sheet.dart';
import '../../widgets/ratings_bottom_sheet.dart';
import '../../widgets/shimmer_loader.dart';

class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  int _currentIndex = 0;
  double? _lat, _lng;

  // Removed local _categories as we now use JOB_CATEGORIES from constants or hardcoded in sheet

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final pos = await LocationService.getCurrentLocation();
      if (pos != null && mounted) {
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
      _loadJobs();
      ref.read(notificationProvider.notifier).fetchNotifications();
      ref.read(applicationProvider.notifier).fetchMyApplications();
    });
  }

  void _loadJobs() async {
    final filters = ref.read(jobFilterProvider);

    // If we still don't have a location and explore mode is off, try once more
    if (!filters.exploreMode && (_lat == null || _lng == null)) {
      final pos = await LocationService.getCurrentLocation();
      if (pos != null && mounted) {
        _lat = pos.latitude;
        _lng = pos.longitude;
      } else if (mounted) {
        // Location unavailable — show a prompt; jobs won't load until location is available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Location is needed to show nearby jobs. Please enable GPS.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    try {
      await ref.read(jobProvider.notifier).fetchNearbyJobs(
            lat: _lat,
            lng: _lng,
            category: filters.category,
            radius: filters.exploreMode ? 99999 : filters.radiusKm,
            minWage: filters.minWage,
            maxWage: filters.maxWage,
            urgentOnly: filters.urgentOnly,
            keyword: filters.keyword,
            jobType: filters.jobType,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _HomePage(
              loadJobs: _loadJobs,
              showFilterSheet: _showFilterSheet,
              getActiveFiltersCount: _getActiveFiltersCount,
              onSOS: _handleSOS,
            ),
            RefreshIndicator(
              onRefresh: () async =>
                  ref.read(jobProvider.notifier).fetchNearbyJobs(),
              child: const SearchProfilesScreen(),
            ),
            const WorkerApplicationsScreen(),
            RefreshIndicator(
              onRefresh: () async =>
                  ref.read(authProvider.notifier).refreshUser(),
              child: const _ProfilePage(),
            ),
          ],
        ),
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
            selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
            unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
            backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            elevation: 16,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                    _currentIndex == 0
                        ? Icons.home_rounded
                        : Icons.home_outlined,
                    size: 24),
                label: LocaleKeys.home.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                    _currentIndex == 1
                        ? Icons.search_rounded
                        : Icons.search_outlined,
                    size: 24),
                label: LocaleKeys.search.tr(),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                    _currentIndex == 2
                        ? Icons.assignment_rounded
                        : Icons.assignment_outlined,
                    size: 24),
                label: LocaleKeys.myJobs.tr(),
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
        // Removed floatingActionButton for SOS
      ),
    );
  }

  Future<void> _handleSOS() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocaleKeys.sosConfirmTitle.tr(), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
        content: Text(LocaleKeys.sosConfirmDesc.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(LocaleKeys.sosCancel.tr())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              _triggerSOS();
            },
            child: Text(LocaleKeys.sosSend.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSOS() async {
    try {
      final pos = await LocationService.getCurrentLocation(context: context);
      if (pos == null) return; // Permission denied or location disabled

      // Persist to backend DB (also emits socket to admin)
      await ApiService.post(ApiConfig.triggerSos, {
        'lat': pos.latitude,
        'lng': pos.longitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LocaleKeys.sosSentSuccess.tr()),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${LocaleKeys.sosSentFail.tr()} $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  void _showFilterSheet() {
    final user = ref.read(authProvider).user;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => JobFilterSheet(currentUser: user),
    );
  }

  int _getActiveFiltersCount() {
    final filters = ref.read(jobFilterProvider);
    int count = 0;
    if (filters.category != null) count++;
    if (filters.minWage > 0 || filters.maxWage < 2000) count++;
    if (filters.radiusKm != null) count++;  // Count only if explicitly selected
    if (filters.urgentOnly) count++;
    if (filters.jobType != null) count++;
    if (filters.exploreMode) count++;
    return count;
  }
}

class _HomePage extends ConsumerWidget {
  final VoidCallback loadJobs;
  final Function showFilterSheet;
  final int Function() getActiveFiltersCount;
  final VoidCallback onSOS;

  const _HomePage({
    required this.loadJobs,
    required this.showFilterSheet,
    required this.getActiveFiltersCount,
    required this.onSOS,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(jobProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isOnline = ref.watch(isOnlineProvider);

    final sortedJobs = List.of(jobState.nearbyJobs)..sort((a, b) => a.distance.compareTo(b.distance));
    final recommendedJobs = sortedJobs.where((job) {
      if (user != null && user.skills.contains(job.category)) return true;
      if (user?.skills != null && user!.skills.any((s) => job.requiredSkills.contains(s))) return true;
      return false;
    }).take(5).toList();

    // Listen to filter changes and reload jobs
    ref.listen(jobFilterProvider, (previous, next) {
      if (previous != next) {
        loadJobs();
      }
    });

    return SafeArea(
      child: Column(
        children: [
          const OfflineBanner(),
          if (!isOnline && jobState.lastUpdated != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.amber.withValues(alpha: 0.1),
              child: Center(
                child: Text(
                  '${LocaleKeys.lastUpdated.tr()} ${DateFormat('hh:mm a').format(jobState.lastUpdated!.toLocal())}',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome & Location
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
                            user?.name.split(' ').first ?? LocaleKeys.kaamgar.tr(),
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
                          // Premium Location Pill
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
                                const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    user?.location.address ?? LocaleKeys.setLocation.tr(),
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
                        // SOS Button
                        GestureDetector(
                          onTap: onSOS,
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.danger.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "SOS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Notification Button
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/notifications'),
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
                
                // KYC Warnings
                if (user?.kycStatus == 'pending')
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.amberAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            LocaleKeys.kycPendingAdminReview.tr(),
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (user?.kycStatus == 'rejected')
                  GestureDetector(
                    onTap: () => context.push('/auth/kyc'),
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: AppColors.danger.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(LocaleKeys.kycRejectedAdmin.tr(), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
                                if (user?.kycNote.isNotEmpty ?? false)
                                  Text(user!.kycNote, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  )
                else if (user?.kycStatus == 'approved')
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 16, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Text(LocaleKeys.verifiedWorker.tr(), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),

                if (user?.isDriver ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildDriverKycBanner(context, user!),
                  ),
              ],
            ),
          ),

          // ── Overlapping Quick Actions ───────────────────────────────
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/chat'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.driving.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.chat_bubble_rounded, color: AppColors.driving, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                LocaleKeys.chatWithRecruiters.tr(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/worker/my-jobs'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.success, Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                LocaleKeys.myJobs.tr(),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Transform.translate(
            offset: const Offset(0, -12),
            child: JobSearchBar(
              activeFiltersCount: getActiveFiltersCount(),
              onFilterTap: () => showFilterSheet(),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -12),
            child: _buildActiveFiltersRow(context, ref),
          ),
          // Jobs list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => loadJobs(),
              child: jobState.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (_, __) => ShimmerLoader.jobCardSkeleton(),
                    )
                  : jobState.nearbyJobs.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off_rounded,
                                      size: 64, color: AppColors.textLight),
                                  const SizedBox(height: 24),
                                  Text(
                                    LocaleKeys.noJobsFound.tr(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    LocaleKeys.adjustFilters.tr(),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 40),
                                  SizedBox(
                                    width: 200,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () => ref
                                          .read(jobFilterProvider.notifier)
                                          .reset(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                      ),
                                      child: Text(LocaleKeys.resetFilters.tr(),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedJobs.length + (recommendedJobs.isNotEmpty ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (recommendedJobs.isNotEmpty && i == 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        LocaleKeys.aiRecommended.tr(),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 280,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: recommendedJobs.length,
                                      itemBuilder: (ctx, idx) {
                                        return SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.85,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: JobCard(
                                              job: recommendedJobs[idx],
                                              onTap: () => context.push('/worker/job/${recommendedJobs[idx].id}'),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    LocaleKeys.nearestJobsTitle.tr(),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }
                            final jobIndex = recommendedJobs.isNotEmpty ? i - 1 : i;
                            return JobCard(
                              job: sortedJobs[jobIndex],
                              onTap: () => context.push('/worker/job/${sortedJobs[jobIndex].id}'),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverKycBanner(BuildContext context, UserModel user) {
    final status = user.driverProfile?.kycStatus ?? 'not_submitted';
    if (status == 'approved') return const SizedBox.shrink();

    Color bgColor = AppColors.warning.withValues(alpha: 0.1);
    Color textColor = AppColors.warning;
    String text = LocaleKeys.driverKycIncomplete.tr();
    IconData icon = Icons.warning_amber_rounded;

    if (status == 'pending') {
      bgColor = AppColors.info.withValues(alpha: 0.1);
      textColor = AppColors.info;
      text = LocaleKeys.driverKycUnderReview.tr();
      icon = Icons.hourglass_top_rounded;
    } else if (status == 'rejected') {
      bgColor = AppColors.danger.withValues(alpha: 0.1);
      textColor = AppColors.danger;
      text = LocaleKeys.driverKycRejected.tr();
      icon = Icons.error_outline_rounded;
    }

    return GestureDetector(
      onTap: () => context.push('/driver/profile'),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersRow(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(jobFilterProvider);
    if (filters.category == null && filters.keyword == null && !filters.exploreMode && filters.radiusKm == null && !filters.urgentOnly && filters.jobType == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (filters.exploreMode)
            _filterChip(context, ref, LocaleKeys.exploreMode.tr(),
                () => ref.read(jobFilterProvider.notifier).setExploreMode(false)),
          if (filters.radiusKm != null && !filters.exploreMode)
            _filterChip(context, ref, '${filters.radiusKm}km',
                () => ref.read(jobFilterProvider.notifier).setRadius(null)),
          if (filters.category != null)
            _filterChip(context, ref, filters.category!.toUpperCase(),
                () => ref.read(jobFilterProvider.notifier).setCategory(null)),
          if (filters.keyword != null)
            _filterChip(context, ref, '"${filters.keyword}"',
                () => ref.read(jobFilterProvider.notifier).setKeyword(null)),
          if (filters.jobType != null)
            _filterChip(context, ref, filters.jobType == 'driver' ? LocaleKeys.driverJobsOnly.tr() : filters.jobType!,
                () => ref.read(jobFilterProvider.notifier).setJobType(null)),
          if (filters.urgentOnly)
            _filterChip(context, ref, LocaleKeys.urgentOnly.tr(),
                () => ref.read(jobFilterProvider.notifier).toggleUrgentOnly()),
        ],
      ),
    );
  }

  Widget _filterChip(
      BuildContext context, WidgetRef ref, String label, VoidCallback onClear) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends ConsumerStatefulWidget {
  const _ProfilePage();

  @override
  ConsumerState<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<_ProfilePage> {
  List<dynamic> _badges = [];
  bool _loadingBadges = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final res = await ApiService.get(ApiConfig.myBadges);
      if (res['success'] == true && mounted) {
        setState(() {
          _badges = (res['data'] as List)
              .where((b) => b['status'] == 'verified')
              .toList();
          _loadingBadges = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingBadges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();
    return RefreshIndicator(
      onRefresh: () async => ref.read(authProvider.notifier).refreshUser(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 24),
            if (user.kycStatus == 'not_submitted')
              GestureDetector(
                onTap: () => context.push('/auth/kyc'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          LocaleKeys.fillKycPrompt.tr(),
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange, size: 14),
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
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 40), // spacer for balance
                      Text(user.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 20, color: AppColors.primary),
                        onPressed: () => context.push('/worker/profile/edit'),
                      ),
                    ],
                  ),
                  Text('+91 ${user.phone}',
                      style: const TextStyle(color: AppColors.textMedium)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isKycApproved
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                        user.isKycApproved
                            ? LocaleKeys.kycVerified.tr()
                            : '${LocaleKeys.kycStatusPrefix.tr()}${user.kycStatus.toUpperCase()}',
                        style: TextStyle(
                            color: user.isKycApproved
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (!_loadingBadges && _badges.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: _badges.length,
                        itemBuilder: (context, index) {
                          final badge = _badges[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.amber.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  kSkillsList
                                      .firstWhere((s) => s.id == badge['skill'],
                                          orElse: () => const SkillInfo(
                                              '', '', Icons.handyman_rounded))
                                      .icon,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                    kSkillsList
                                        .firstWhere(
                                            (s) => s.id == badge['skill'],
                                            orElse: () => const SkillInfo(
                                                '', '', Icons.handyman_rounded))
                                        .name,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber)),
                                const SizedBox(width: 2),
                                const Icon(Icons.verified_rounded,
                                    size: 12, color: Colors.amber),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            _statRow(context, [
              {
                'label': LocaleKeys.jobsDone.tr(),
                'value': '${user.completedJobsCount}',
                'icon': Icons.check_circle_rounded,
                'iconColor': Colors.green
              },
              {
                'label': LocaleKeys.rating.tr(),
                'value': user.rating.average.toStringAsFixed(1),
                'icon': Icons.star_rounded,
                'iconColor': Colors.amber
              },
              {
                'label': LocaleKeys.daysOnApp.tr(),
                'value': '${DateTime.now().difference(user.createdAt).inDays}',
                'widget': _buildCalendarIcon()
              },
            ]),
            if (user.verifiedSkills.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.verifiedSkills
                        .map((s) {
                          final skill = kSkillsList.firstWhere(
                            (element) => element.id.toLowerCase() == s.toLowerCase(),
                            orElse: () => SkillInfo(s, s, Icons.verified_rounded),
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade600,
                                  Colors.teal.shade500,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(skill.icon,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  skill.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ),
            ],
            if (user.skills
                .where((s) => !user.verifiedSkills.any((vs) => vs.toLowerCase() == s.toLowerCase()))
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.skills
                        .where((s) => !user.verifiedSkills.any((vs) => vs.toLowerCase() == s.toLowerCase()))
                        .map((s) => Chip(
                              label:
                                  Text(s, style: const TextStyle(fontSize: 12)),
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _menuTile(context, Icons.star_border_rounded,
                LocaleKeys.viewRecruiterFeedback.tr(), () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => RatingsBottomSheet(userId: user.id),
              );
            }),
            _menuTile(context, Icons.edit_rounded, LocaleKeys.editProfile.tr(),
                () => context.push('/worker/profile')),
            _menuTile(context, Icons.gavel_rounded, LocaleKeys.myDisputes.tr(),
                () => context.push('/disputes/my')),
            if (user.isDriver)
              _menuTile(
                  context,
                  Icons.drive_eta_rounded,
                  LocaleKeys.driverProfile.tr(),
                  () => context.push('/driver/profile')),
            _menuTile(
                context,
                Icons.notifications_rounded,
                LocaleKeys.notifications.tr(),
                () => context.push('/worker/notifications')),
            _menuTile(
                context,
                Icons.settings_suggest_rounded,
                'notificationSettingsTitle'.tr(),
                () => context.push('/worker/notification-settings')),
            

            _menuTile(
                context,
                Icons.workspace_premium_rounded,
                'previousWork'.tr(),
                () => context.push('/worker/portfolio')),
            _menuTile(
                context,
                Icons.card_membership_rounded,
                LocaleKeys.skillBadges.tr(),
                () => context.push('/worker/skill-badges')),
            _menuTile(context, Icons.card_giftcard_rounded,
                LocaleKeys.referrals.tr(), () => context.push('/referral')),
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
            // Delete Account moved to Edit Profile

            _menuTile(context, Icons.gavel_outlined, 'legalAndInformation'.tr(),
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

  Widget _buildCalendarIcon() {
    final now = DateTime.now();
    final day = now.day.toString();
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    final month = months[now.month - 1];

    return Container(
      width: 32,
      height: 34,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              padding: const EdgeInsets.symmetric(vertical: 1),
              decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5))),
              child: Text(month,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 6,
                      fontWeight: FontWeight.bold)),
            ),
            Text(day,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, List<Map<String, dynamic>> stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((s) => _stat(s)).toList(),
      ),
    );
  }

  Widget _stat(Map<String, dynamic> s) => Expanded(
        child: ClipRect(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s['widget'] != null)
                SizedBox(
                    height: 36, child: Center(child: s['widget'] as Widget))
              else if (s['icon'] != null)
                SizedBox(
                    height: 36,
                    child: Center(
                        child: Icon(s['icon'] as IconData,
                            size: 24, color: s['iconColor'] as Color?)))
              else
                const SizedBox(height: 36),
              const SizedBox(height: 2),
              Text(
                s['value'] ?? '0',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                s['label'] ?? '',
                style: const TextStyle(fontSize: 9, color: AppColors.textLight),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      );

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
}
