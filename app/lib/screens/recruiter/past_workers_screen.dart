import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import '../../providers/stats_provider.dart';

class PastWorkersScreen extends ConsumerStatefulWidget {
  const PastWorkersScreen({super.key});

  @override
  ConsumerState<PastWorkersScreen> createState() => _PastWorkersScreenState();
}

class _PastWorkersScreenState extends ConsumerState<PastWorkersScreen> {
  bool _localLoading = false;

  void _showReinviteSheet(String workerId, String workerName) async {
    setState(() => _localLoading = true);

    try {
      final res = await ApiService.get('${ApiConfig.myJobs}?status=open');

      setState(() => _localLoading = false);

      final List<dynamic> activeJobs = res['data'] ?? [];
      if (activeJobs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocaleKeys.noActiveJobsInvite.tr())),
        );
        return;
      }

      String? selectedJobId;

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${LocaleKeys.reInvite.tr()} $workerName',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text(LocaleKeys.selectJob.tr(),
                    style: const TextStyle(color: AppColors.textMedium)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedJobId,
                      hint: Text(LocaleKeys.selectJob.tr()),
                      items: activeJobs.map((job) {
                        return DropdownMenuItem<String>(
                          value: job['_id'],
                          child: Text(job['title']),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedJobId = val),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: selectedJobId == null
                        ? null
                        : () async {
                            final inviteRes = await ApiService.post(
                                '${ApiConfig.reinviteWorker}/$workerId',
                                {'jobId': selectedJobId});
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              if (inviteRes['success'] == true) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(LocaleKeys.invitationSent.tr()),
                                      backgroundColor: AppColors.success),
                                );
                              }
                            }
                          },
                    child: Text(LocaleKeys.reInvite.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _localLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(pastWorkersProvider));
  }

  Widget _buildWorkerCard(dynamic worker, DateTime date) {
    final List<dynamic> skills = worker['skills'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (worker['workerId'] != null) {
            context.push('/public-profile/${worker['workerId']}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                      (worker['name'] != null && worker['name'].isNotEmpty)
                          ? worker['name'][0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(worker['name'] ?? LocaleKeys.unknownWorker.tr(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if (worker['kycStatus'] == 'approved')
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified,
                                  color: AppColors.primary, size: 16),
                            ),
                        ],
                      ),
                      Text(worker['phone'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 16),
                          Text(
                              ' ${worker['rating']?.toStringAsFixed(1) ?? LocaleKeys.notAvailable.tr()}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 14),
                          const SizedBox(width: 4),
                          Text('${worker['completedJobsCount'] ?? 0} Jobs Done', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                        ],
                      ),
                      if (worker['location'] != null && worker['location'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.textLight, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(worker['location'], style: const TextStyle(fontSize: 11, color: AppColors.textMedium), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills
                    .take(3)
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(s.toString(),
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textDark)),
                        ))
                    .toList(),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${LocaleKeys.lastHired.tr()}${DateFormat('dd MMM yyyy').format(date.toLocal())}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
                      Text(
                          '${LocaleKeys.totalTimesHired.tr()}${worker['totalTimesHired']}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _showReinviteSheet(worker['workerId'] ?? '', worker['name'] ?? LocaleKeys.worker.tr()),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                  child: Text(LocaleKeys.reInvite.tr(),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pastWorkersAsync = ref.watch(pastWorkersProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(title: Text(LocaleKeys.pastWorkers.tr())),
      body: _localLoading
          ? const Center(child: CircularProgressIndicator())
          : pastWorkersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (workers) => workers.isEmpty
                  ? Center(
                      child: Text(LocaleKeys.noPastWorkers.tr(),
                          style: const TextStyle(
                              color: AppColors.textMedium, fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(pastWorkersProvider.future),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: workers.length,
                        itemBuilder: (context, index) {
                          final worker = workers[index];
                          DateTime? date;
                          try {
                            if (worker['lastHiredOn'] != null) {
                              date = DateTime.parse(worker['lastHiredOn']);
                            }
                          } catch (e) {
                            date = null;
                          }
                          return _buildWorkerCard(
                              worker, date ?? DateTime.now());
                        },
                      ),
                    ),
            ),
    );
  }
}
