import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../providers/stats_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/application_provider.dart';
import '../../providers/rating_provider.dart';
import '../../widgets/rating_dialog.dart';
import '../../l10n/locale_keys.g.dart';
import '../../widgets/shimmer_loader.dart';
import '../../utils/app_utils.dart';
import '../../providers/saved_jobs_provider.dart';
import '../../services/job_service.dart';
import '../../services/cache_service.dart';
import '../../models/job_model.dart';
import '../../widgets/job_card.dart';
import '../../providers/connectivity_provider.dart';

class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});

  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(workerStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.myJobs.tr()),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: LocaleKeys.all.tr()),
            Tab(text: 'saved'.tr()),
            Tab(text: LocaleKeys.totalApplied.tr()),
            Tab(text: LocaleKeys.hired.tr()),
            Tab(text: LocaleKeys.statusCompleted.tr()),
          ],
        ),
      ),
      body: Column(
        children: [
          statsAsync.when(
            data: (stats) => _buildStatsRow(stats),
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => const SizedBox(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                WorkerApplicationList(status: null),
                SavedJobsList(),
                WorkerApplicationList(status: 'applied'),
                WorkerApplicationList(status: 'accepted'),
                WorkerApplicationList(status: 'completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statCard(LocaleKeys.totalApplied.tr(),
              stats['totalApplied'].toString(), Colors.orange),
          _statCard(LocaleKeys.hired.tr(), stats['totalAccepted'].toString(),
              Colors.blue),
          _statCard(LocaleKeys.statusCompleted.tr(),
              stats['totalCompleted'].toString(), Colors.green),
          _statCard(LocaleKeys.rating.tr(), '⭐ ${stats['averageRating']}',
              Colors.amber),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class WorkerApplicationList extends ConsumerWidget {
  final String? status;
  const WorkerApplicationList({super.key, this.status});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'applied':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'withdrawn':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'applied':
        return LocaleKeys.statusPending.tr();
      case 'accepted':
        return LocaleKeys.statusAccepted.tr();
      case 'completed':
        return LocaleKeys.statusCompleted.tr();
      case 'rejected':
        return LocaleKeys.statusRejected.tr();
      case 'withdrawn':
        return LocaleKeys.statusWithdrawn.tr();
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(applicationProvider);

    final applications = status == null
        ? state.myApplications
        : state.myApplications.where((a) => a.status == status).toList();

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(applicationProvider.notifier).fetchMyApplications(),
      child: (state.isLoading && applications.isEmpty)
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (_, __) => ShimmerLoader.jobCardSkeleton(),
            )
          : applications.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment_rounded,
                              size: 64, color: AppColors.textLight),
                          const SizedBox(height: 24),
                          Text(
                            LocaleKeys.noApplications.tr(),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            LocaleKeys.applyForJobsToSee.tr(),
                            style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    final job = app.job;
                    final status = app.status;

                    return GestureDetector(
                      onTap: () {
                        if (job != null) {
                          context.push('/worker/job/${job.id}');
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              AppColors.getCategoryIcon(
                                                  job?.category ?? ''),
                                              size: 24,
                                              color: AppColors.getCategoryColor(
                                                  job?.category ?? ''),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                job?.title ?? 'Job',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 18),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _getStatusLabel(status),
                                          style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(job?.recruiter?.name ?? '',
                                      style: const TextStyle(
                                          color: AppColors.textMedium,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        job?.formattedWage ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.success,
                                            fontSize: 16),
                                      ),
                                      Text(
                                        DateFormat('dd MMM yyyy')
                                            .format(app.createdAt.toLocal()),
                                        style: const TextStyle(
                                            color: AppColors.textLight,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (status == 'completed' &&
                                app.workerRating != null) ...[
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                        LocaleKeys.recruiterRatedYou.tr(args: [
                                          app.workerRating!['score'].toString()
                                        ]),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                            if (status == 'completed' &&
                                app.recruiterRating == null)
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: AppColors.border
                                              .withValues(alpha: 0.5))),
                                ),
                                child: TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => RatingDialog(
                                        title: LocaleKeys.rateRecruiter.tr(),
                                        subtitle: LocaleKeys
                                            .rateRecruiterSubtitle
                                            .tr(namedArgs: {
                                          'name': job?.recruiter?.name ??
                                              "this recruiter"
                                        }),
                                        onSubmit: (score, comment) async {
                                          final ratingResult = await ref
                                              .read(ratingProvider.notifier)
                                              .submitRating(
                                                jobId: app.jobId,
                                                score: score,
                                                comment: comment,
                                              );
                                          if (context.mounted) {
                                            if (ratingResult['success'] ==
                                                true) {
                                              ref
                                                  .read(applicationProvider
                                                      .notifier)
                                                  .fetchMyApplications();
                                              AppUtils.showTopSnackBar(context,
                                                  '🌟 ${LocaleKeys.ratingSubmitted.tr()}',
                                                  isError: false);
                                            } else {
                                              AppUtils.showTopSnackBar(
                                                  context,
                                                  ratingResult['message'] ??
                                                      LocaleKeys.error.tr());
                                            }
                                          }
                                        },
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14)),
                                  icon: const Icon(Icons.star_rounded,
                                      size: 20, color: AppColors.primary),
                                  label: Text(LocaleKeys.rateRecruiter.tr(),
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15)),
                                ),
                              ),
                            if (status == 'completed' &&
                                app.recruiterRating != null)
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                      top: BorderSide(
                                          color: AppColors.border
                                              .withValues(alpha: 0.5))),
                                  color:
                                      AppColors.bgLight.withValues(alpha: 0.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 18, color: AppColors.warning),
                                    const SizedBox(width: 8),
                                    Text(
                                        LocaleKeys.youRated.tr(args: [
                                          app.recruiterRating!['score']
                                              .toString()
                                        ]),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textMedium)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class SavedJobsList extends ConsumerWidget {
  const SavedJobsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedJobsProvider);
    final isOnline = ref.watch(isOnlineProvider);

    if (savedIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 64, color: AppColors.textLight),
            const SizedBox(height: 24),
            Text(
              'noSavedJobs'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              LocaleKeys.applyForJobsToSee.tr(),
              style: const TextStyle(fontSize: 16, color: AppColors.textLight, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<JobModel?>>(
      future: isOnline ? Future.wait(savedIds.map((id) => JobService.getJobById(id))) : CacheService.getCachedJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, __) => ShimmerLoader.jobCardSkeleton(),
          );
        }

        final jobs = snapshot.data?.whereType<JobModel>().toList() ?? [];
        if (isOnline) {
          // Sync Cache
          for (var job in jobs) {
            CacheService.cacheJob(job);
          }
        }

        if (jobs.isEmpty) {
          return Center(child: Text('allSavedJobsUnavailable'.tr()));
        }

        return Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.orange.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('offlineModeSavedJobs'.tr(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return JobCard(
                    job: job,
                    onTap: () => context.push('/worker/job/${job.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

