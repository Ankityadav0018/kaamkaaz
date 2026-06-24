import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/application_provider.dart';
import '../../providers/rating_provider.dart';
import '../../models/application_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/rating_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import '../../widgets/shimmer_loader.dart';
import '../../utils/app_utils.dart';

class WorkerApplicationsScreen extends ConsumerStatefulWidget {
  const WorkerApplicationsScreen({super.key});

  @override
  ConsumerState<WorkerApplicationsScreen> createState() =>
      _WorkerApplicationsScreenState();
}

class _WorkerApplicationsScreenState
    extends ConsumerState<WorkerApplicationsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(applicationProvider.notifier).fetchMyApplications());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applicationProvider);
    final filtered = _filter == 'all'
        ? state.myApplications
        : state.myApplications.where((a) => a.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.myApplications.tr(),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', LocaleKeys.search.tr()),
                  _filterChip('applied', LocaleKeys.pending.tr()),
                  _filterChip('accepted', LocaleKeys.selected.tr()),
                  _filterChip('completed', LocaleKeys.completed.tr()),
                  _filterChip('rejected', LocaleKeys.rejected.tr()),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.read(applicationProvider.notifier).fetchMyApplications(),
              child: state.isLoading && filtered.isEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (_, __) => ShimmerLoader.jobCardSkeleton(),
                    )
                  : filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.15),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.assignment_rounded,
                                      size: 64, color: AppColors.textLight),
                                  const SizedBox(height: 24),
                                  Text(
                                    _filter == 'all'
                                        ? LocaleKeys.noApplicationsYet.tr()
                                        : LocaleKeys.noFilteredApplications
                                            .tr(args: [_filter]),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(LocaleKeys.applyForJobsToSee.tr(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textLight,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _AppCard(app: filtered[i]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.inputBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textMedium,
            )),
      ),
    );
  }
}

class _AppCard extends ConsumerWidget {
  final ApplicationModel app;
  const _AppCard({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    String effectiveStatus = app.status;
    if (app.job?.status == 'completed') {
      effectiveStatus = 'completed';
    }

    switch (effectiveStatus) {
      case 'accepted':
        statusColor = AppColors.success;
        statusText = LocaleKeys.youAreSelected.tr();
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'completed':
        statusColor = AppColors.success; // Changed to green badge as requested
        statusText = LocaleKeys.workCompleted.tr();
        statusIcon = Icons.task_alt_rounded;
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        statusText = LocaleKeys.notSelected.tr();
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.warning;
        statusText = LocaleKeys.applicationPending.tr();
        statusIcon = Icons.hourglass_empty_rounded;
        break;
    }

    final job = app.job;

    return GestureDetector(
      onTap: () {
        if (job != null) {
          context.push('/worker/job/${job.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
          border: (effectiveStatus == 'accepted' || effectiveStatus == 'completed')
              ? Border.all(
                  color: statusColor.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(job?.title ?? 'Job',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 16, color: statusColor),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (job != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.currency_rupee_rounded,
                            size: 18, color: AppColors.success),
                        Text(job.formattedWage,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success)),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on_rounded,
                            size: 18, color: AppColors.textLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            job.location.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textMedium,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                      LocaleKeys.appliedOn.tr(args: [
                        DateFormat('dd MMM yyyy').format(app.createdAt.toLocal())
                      ]),
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Action buttons
            if (effectiveStatus == 'applied')
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: TextButton.icon(
                  onPressed: () async {
                    final result = await ref
                        .read(applicationProvider.notifier)
                        .withdraw(app.id);
                    if (context.mounted) {
                      AppUtils.showTopSnackBar(context, result['message'] ?? '',
                          isError: result['success'] != true);
                    }
                  },
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.cancel_outlined,
                      size: 20, color: AppColors.danger),
                  label: Text(LocaleKeys.withdraw.tr(),
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            if (effectiveStatus == 'completed' && app.recruiterRating == null)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => RatingDialog(
                        title: LocaleKeys.rateRecruiter.tr(),
                        subtitle: LocaleKeys.rateRecruiterSubtitle
                            .tr(namedArgs: {
                          'name': app.job?.recruiter?.name ?? "this recruiter"
                        }),
                        onSubmit: (score, comment) async {
                          final result = await ref
                              .read(ratingProvider.notifier)
                              .submitRating(
                                jobId: app.jobId,
                                score: score,
                                comment: comment,
                              );
                          if (context.mounted) {
                            if (result['success'] == true) {
                              ref
                                  .read(applicationProvider.notifier)
                                  .fetchMyApplications();
                              AppUtils.showTopSnackBar(context,
                                  '🌟 ${LocaleKeys.ratingSubmitted.tr()}',
                                  isError: false);
                            } else {
                              AppUtils.showTopSnackBar(context,
                                  result['message'] ?? LocaleKeys.error.tr());
                            }
                          }
                        },
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: const Icon(Icons.star_rounded,
                      size: 20, color: AppColors.primary),
                  label: Text(LocaleKeys.rateRecruiter.tr(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                ),
              ),
            if (effectiveStatus == 'completed' && app.recruiterRating != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                        LocaleKeys.youRated.tr(args: [
                          (app.recruiterRating?['score'] ?? 0).toString()
                        ]),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
