import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/application_model.dart';
import '../utils/app_colors.dart';
import '../l10n/locale_keys.g.dart';
import '../utils/constants.dart';

class ApplicantCardWidget extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const ApplicantCardWidget({
    super.key,
    required this.application,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final worker = application.worker;
    if (worker == null) return const SizedBox();

    Color statusColor;
    String statusText;
    switch (application.status) {
      case 'accepted':
        statusColor = AppColors.success;
        statusText = '✅ ${LocaleKeys.accepted.tr()}';
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusText = '✅ ${LocaleKeys.completed.tr()}';
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        statusText = '❌ ${LocaleKeys.rejected.tr()}';
        break;
      default:
        statusColor = AppColors.warning;
        statusText = '⏳ ${LocaleKeys.pending.tr()}';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: application.status == 'accepted'
            ? Border.all(
                color: AppColors.success.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/public-profile/${worker.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(worker.name[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(worker.name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700))),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(statusText,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor)),
                            ),
                            if (worker.isDriver &&
                                worker.driverProfile?.kycStatus ==
                                    'verified') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: AppColors.driving
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_rounded,
                                        size: 10, color: AppColors.driving),
                                    const SizedBox(width: 4),
                                    Text(
                                        LocaleKeys.verifiedDriver
                                            .tr()
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.driving)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (application.job != null) ...[
                          const SizedBox(height: 4),
                          Text('${LocaleKeys.jobColon.tr()}: ${application.job!.title}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 14, color: AppColors.accent),
                            Text(
                                ' ${worker.rating.average.toStringAsFixed(1)} (${worker.rating.count})',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            const Icon(Icons.check_circle_outline,
                                size: 14, color: AppColors.success),
                            Text(
                                ' ${worker.completedJobsCount} ${LocaleKeys.jobsDone.tr()}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textMedium)),
                          ],
                        ),
                        if (worker.village.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 14, color: AppColors.primary),
                              Text(' ${worker.village}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium)),
                            ],
                          ),
                        ],
                        if (worker.verifiedSkills.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: worker.verifiedSkills
                                .map((s) {
                                  final skill = kSkillsList.firstWhere(
                                    (element) => element.id.toLowerCase() == s.toLowerCase(),
                                    orElse: () => SkillInfo(s, s, Icons.verified_rounded),
                                  );
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade600,
                                          Colors.teal.shade500,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withValues(alpha: 0.25),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(skill.icon,
                                            size: 10, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(skill.name,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(width: 3),
                                        const Icon(Icons.verified_user_rounded,
                                            size: 9, color: Colors.white),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                        ],
                        if (worker.skills
                            .where((s) => !worker.verifiedSkills.any((vs) => vs.toLowerCase() == s.toLowerCase()))
                            .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: worker.skills
                                .where(
                                    (s) => !worker.verifiedSkills.any((vs) => vs.toLowerCase() == s.toLowerCase()))
                                .take(4)
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(s,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                          ),
                        ],
                        if (application.message.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('"${application.message}"',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMedium,
                                    fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (application.status == 'applied')
            Container(
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.danger),
                      label: Text(LocaleKeys.reject.tr(),
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Container(width: 1, height: 24, color: AppColors.border),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.success),
                      label: Text(LocaleKeys.accept.tr(),
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
