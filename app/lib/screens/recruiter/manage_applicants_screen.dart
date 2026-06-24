import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/application_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/rating_provider.dart';
import '../../models/application_model.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../widgets/applicant_card_widget.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';

class ManageApplicantsScreen extends ConsumerStatefulWidget {
  final String jobId;
  const ManageApplicantsScreen({super.key, required this.jobId});

  @override
  ConsumerState<ManageApplicantsScreen> createState() =>
      _ManageApplicantsScreenState();
}

class _ManageApplicantsScreenState
    extends ConsumerState<ManageApplicantsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref
        .read(applicationProvider.notifier)
        .fetchJobApplications(widget.jobId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applicationProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: Text(LocaleKeys.manageApplicants.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop()),
        actions: [
          if (state.jobApplications.any((a) => a.status == 'accepted' || a.status == 'completed'))
            IconButton(
              icon: const Icon(Icons.group_add_rounded, color: AppColors.primary),
              tooltip: LocaleKeys.groupChatTooltip.tr(),
              onPressed: () => context.push('/chat/group/${widget.jobId}'),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                  '${state.jobApplications.length} ${LocaleKeys.total.tr()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async => ref
                  .read(applicationProvider.notifier)
                  .fetchJobApplications(widget.jobId),
              child: Column(
                children: [
                  // Accepted worker banner
                  if (state.jobApplications.any(
                      (a) => a.status == 'accepted' || a.status == 'completed'))
                    _AcceptedBanner(
                      application: state.jobApplications.firstWhere((a) =>
                          a.status == 'accepted' || a.status == 'completed'),
                      onMarkCompleted: () => _markCompleted(widget.jobId),
                      onShowRating: (jId, wId, wName) =>
                          _showRatingBottomSheet(context, jId, wId, wName),
                    ),
                  // Applicants list
                  Expanded(
                    child: state.jobApplications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('📭',
                                    style: TextStyle(fontSize: 56)),
                                const SizedBox(height: 12),
                                Text(LocaleKeys.noApplicationsYet.tr(),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                Text(LocaleKeys.workersWillApplySoon.tr(),
                                    style: const TextStyle(
                                        color: AppColors.textLight)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.jobApplications.length,
                            itemBuilder: (_, i) => ApplicantCardWidget(
                              application: state.jobApplications[i],
                              onAccept:
                                  state.jobApplications[i].status == 'applied'
                                      ? () => _accept(state.jobApplications[i])
                                      : null,
                              onReject: state.jobApplications[i].status ==
                                      'applied'
                                  ? () => _reject(state.jobApplications[i].id)
                                  : null,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _accept(ApplicationModel app) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocaleKeys.acceptApplicant.tr(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(LocaleKeys.acceptWorkerDetails
            .tr(args: [app.worker?.name ?? "this worker"])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LocaleKeys.cancel.tr())),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final result =
                  await ref.read(applicationProvider.notifier).accept(app.id);

              if (result['success'] == true) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(LocaleKeys.workerAccepted.tr()),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['message'] ?? 'Error'),
                  backgroundColor: AppColors.danger,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: Text(LocaleKeys.accept.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _reject(String appId) async {
    final result = await ref.read(applicationProvider.notifier).reject(appId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor:
            result['success'] == true ? AppColors.warning : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _markCompleted(String jobId) async {
    final result = await ref
        .read(jobProvider.notifier)
        .updateJobStatus(jobId, 'completed');
    if (result['success'] == true) {
      await ref.read(applicationProvider.notifier).fetchJobApplications(jobId);
      if (!mounted) return;

      final state = ref.read(applicationProvider);
      final application = state.jobApplications.firstWhere(
          (a) => a.status == 'completed',
          orElse: () =>
              state.jobApplications.firstWhere((a) => a.status == 'accepted'));

      _showRatingBottomSheet(context, jobId, application.workerId,
          application.worker?.name ?? 'Worker');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LocaleKeys.jobMarkedCompleted.tr()),
        backgroundColor: AppColors.success,
      ));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Error completing job'),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  void _showRatingBottomSheet(
      BuildContext context, String jobId, String workerId, String workerName) {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(LocaleKeys.rateThisWorker.tr(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(workerName,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                    (i) => GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedRating = i + 1),
                          child: Icon(
                              i < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 48,
                              color: Colors.amber),
                        )),
              ),
              const SizedBox(height: 8),
              Text(_ratingLabel(selectedRating),
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              VoiceTextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText:
                      '${LocaleKeys.addComment.tr()} (${LocaleKeys.optional.tr()})',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 2,
                maxLength: 200,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () => _submitRating(jobId, workerId, selectedRating,
                          commentController.text),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  child: Text(LocaleKeys.submitRating.tr()),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(LocaleKeys.skipForNow.tr())),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return LocaleKeys.poor.tr();
      case 2:
        return LocaleKeys.belowAverage.tr();
      case 3:
        return LocaleKeys.good.tr();
      case 4:
        return LocaleKeys.veryGood.tr();
      case 5:
        return LocaleKeys.excellent.tr();
      default:
        return LocaleKeys.tapStarToRate.tr();
    }
  }

  Future<void> _submitRating(
      String jobId, String workerId, int score, String comment) async {
    final result = await ref
        .read(ratingProvider.notifier)
        .submitRating(jobId: jobId, score: score, comment: comment);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pop(context);
      ref.read(applicationProvider.notifier).fetchJobApplications(jobId);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: 8),
              Text(LocaleKeys.ratingSubmitted.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(LocaleKeys.ratingSubmittedThanks.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LocaleKeys.okButton.tr()),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Error'),
          backgroundColor: AppColors.danger));
    }
  }
}

class _AcceptedBanner extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onMarkCompleted;
  final Function(String, String, String) onShowRating;

  const _AcceptedBanner({
    required this.application,
    required this.onMarkCompleted,
    required this.onShowRating,
  });

  @override
  Widget build(BuildContext context) {
    final worker = application.worker;
    if (worker == null) return const SizedBox();
    final isCompleted = application.status == 'completed';
    final hasRated = application.workerRating != null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            isCompleted ? AppColors.heroGradient : AppColors.greenGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  isCompleted
                      ? Icons.task_alt_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white),
              const SizedBox(width: 8),
              Text(
                  isCompleted
                      ? LocaleKeys.workCompleted.tr()
                      : LocaleKeys.workerSelected.tr(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.push('/public-profile/${worker.id}'),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  child: Text(
                    (worker.name.isNotEmpty)
                        ? worker.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      Text('📞 ${worker.phone}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                      if (worker.village.isNotEmpty)
                        Text('📍 ${worker.village}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/chat/${application.jobId}/${worker.id}'),
                    icon:
                        const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(LocaleKeys.chatWithWorker.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (!isCompleted)
            ElevatedButton.icon(
              onPressed: onMarkCompleted,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(LocaleKeys.markCompleted.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.success,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          else if (!hasRated)
            ElevatedButton.icon(
              onPressed: () =>
                  onShowRating(application.jobId, worker.id, worker.name),
              icon: const Icon(Icons.star_rounded, size: 18),
              label: Text(LocaleKeys.rateWorker.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(
                        5,
                        (i) => Icon(
                              i < (application.workerRating?['score'] ?? 0)
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.white,
                              size: 16,
                            )),
                    const SizedBox(width: 8),
                    Text(
                        LocaleKeys.youRated.tr(args: [
                          (application.workerRating?['score'] ?? 0).toString()
                        ]),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

          if (isCompleted && application.job?.hasDispute != true) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await context.push('/disputes/raise/${application.jobId}');
                  if (result == true) {
                    // ignore: unused_result
                    // The screen will refresh the state or caller should refresh
                  }
                },
                icon: const Icon(Icons.gavel_rounded, color: Colors.white, size: 18),
                label: Text(
                  LocaleKeys.raiseDispute.tr(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
