import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/job_model.dart';
import '../utils/app_colors.dart';
import '../l10n/locale_keys.g.dart';
import '../providers/saved_jobs_provider.dart';

class JobCard extends ConsumerWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(savedJobsProvider).contains(job.id);
    
    // Format date properly
    final dateStr = DateFormat('dd MMM, yyyy').format(job.createdAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Icon/Logo
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getCategoryIcon(job.category),
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title & Recruiter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              job.recruiter?.name ?? LocaleKeys.recruiter.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Bookmark Action
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: isSaved ? AppColors.primary : Colors.grey[400],
                          size: 28,
                        ),
                        onPressed: () {
                          ref.read(savedJobsProvider.notifier).toggleSave(job);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tags Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(
                        icon: Icons.currency_rupee_rounded,
                        text: job.formattedWage.replaceAll('₹', '').trim(),
                        color: AppColors.success,
                        bgColor: AppColors.success.withValues(alpha: 0.1),
                      ),
                      if (job.isUrgent)
                        _buildTag(
                          icon: Icons.local_fire_department_rounded,
                          text: LocaleKeys.urgent.tr(),
                          color: Colors.red,
                          bgColor: Colors.red.withValues(alpha: 0.1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Location and Time
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.location.address.isNotEmpty
                              ? job.location.address
                              : LocaleKeys.locationNotSpecified.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Footer / Apply Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: job.isApplied ? Colors.grey[50] : AppColors.primary.withValues(alpha: 0.03),
                border: Border(
                  top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: job.isApplied ? Colors.grey[300] : AppColors.primary,
                    foregroundColor: job.isApplied ? Colors.grey[600] : Colors.white,
                    elevation: job.isApplied ? 0 : 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        job.isApplied
                            ? LocaleKeys.applied.tr()
                            : LocaleKeys.applyNow.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (!job.isApplied) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({required IconData icon, required String text, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'construction':
        return Icons.construction_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'driver':
        return Icons.drive_eta_rounded;
      case 'farming':
        return Icons.agriculture_rounded;
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'painting':
        return Icons.format_paint_rounded;
      default:
        return Icons.work_outline_rounded;
    }
  }
}
