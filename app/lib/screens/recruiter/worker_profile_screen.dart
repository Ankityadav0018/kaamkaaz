import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/application_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../models/rating_model.dart' as detail;
import '../../services/rating_service.dart';
import '../../utils/constants.dart';

class WorkerPublicProfileScreen extends ConsumerStatefulWidget {
  final String applicationId;
  const WorkerPublicProfileScreen({super.key, required this.applicationId});

  @override
  ConsumerState<WorkerPublicProfileScreen> createState() =>
      _WorkerPublicProfileScreenState();
}

class _WorkerPublicProfileScreenState
    extends ConsumerState<WorkerPublicProfileScreen> {
  UserModel? _worker;
  String? _jobId;
  List<detail.RatingModel> _ratings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data =
        await ApplicationService.getWorkerFullProfile(widget.applicationId);
    if (data != null) {
      final worker = data['worker'] as UserModel;
      final jobId = data['jobId'] as String;
      final ratingsRes = await RatingService.getUserRatings(worker.id);
      if (mounted) {
        setState(() {
          _worker = worker;
          _jobId = jobId;
          _ratings = ratingsRes;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_worker == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(LocaleKeys.workerProfileNotAvailable.tr())),
      );
    }

    final worker = _worker!;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.heroGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      child: Text(
                          worker.name.isNotEmpty
                              ? worker.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    Text(worker.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    if (worker.village.isNotEmpty)
                      Text(worker.village,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.greenGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📞 ${LocaleKeys.contactDetailsRevealed.tr()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            )),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('+91 ${worker.phone}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                )),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    context.push('/chat/$_jobId/${worker.id}'),
                                icon: const Icon(
                                    Icons.chat_bubble_outline_rounded),
                                label: Text(LocaleKeys.chatWithWorker.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => launchUrl(Uri.parse(
                                    'https://wa.me/91${worker.phone}')),
                                icon: const Text('💬',
                                    style: TextStyle(fontSize: 16)),
                                label: Text(LocaleKeys.whatsApp.tr()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  foregroundColor: const Color(0xFF2E7D32),
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                            child: _stat(
                                '⭐',
                                worker.rating.average.toStringAsFixed(1),
                                LocaleKeys.rating.tr())),
                        _divider(),
                        Expanded(
                            child: _stat('✅', '${worker.completedJobsCount}',
                                LocaleKeys.jobsDone.tr())),
                        _divider(),
                        Expanded(
                            child: _stat('📅', '${worker.experienceDays}',
                                LocaleKeys.daysExp.tr())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (worker.verifiedSkills.isNotEmpty ||
                      worker.skills.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.cardShadow),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LocaleKeys.skills.tr(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 12),
                          if (worker.verifiedSkills.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: worker.verifiedSkills
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
                            const SizedBox(height: 12),
                          ],
                          if (worker.skills
                              .where((s) => !worker.verifiedSkills.any((vs) => vs.toLowerCase() == s.toLowerCase()))
                              .isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: worker.skills
                                  .where(
                                      (s) => !worker.verifiedSkills.any((vs) => vs.toLowerCase() == s.toLowerCase()))
                                  .map((s) => Chip(
                                        label: Text(s,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.08),
                                        side: BorderSide(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.2)),
                                      ))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Previous Work / Portfolio Section
                  if (worker.portfolio.isNotEmpty) ...[
                    Text(
                      'previousWork'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: worker.portfolio.length,
                        itemBuilder: (context, index) {
                          final item = worker.portfolio[index];
                          final description = context.locale.languageCode == 'hi'
                              ? (item.descriptionHindi.isNotEmpty ? item.descriptionHindi : item.descriptionEnglish)
                              : (item.descriptionEnglish.isNotEmpty ? item.descriptionEnglish : item.descriptionHindi);

                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.mediaUrl.isNotEmpty)
                                    Expanded(
                                      flex: 3,
                                      child: Stack(
                                        children: [
                                          item.mediaType == 'image'
                                              ? CachedNetworkImage(
                                                  imageUrl: item.mediaUrl,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    color: Colors.grey.shade100,
                                                    child: const Center(child: CircularProgressIndicator()),
                                                  ),
                                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  color: Colors.black87,
                                                  child: const Center(
                                                    child: Icon(Icons.video_library_rounded, color: Colors.white, size: 40),
                                                  ),
                                                ),
                                          if (item.mediaType == 'video')
                                            Positioned.fill(
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () async {
                                                    final uri = Uri.parse(item.mediaUrl);
                                                    if (await canLaunchUrl(uri)) {
                                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                    }
                                                  },
                                                  child: Center(
                                                    child: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 24),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (item.mediaType == 'image')
                                            Positioned.fill(
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () async {
                                                    final uri = Uri.parse(item.mediaUrl);
                                                    if (await canLaunchUrl(uri)) {
                                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  else
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        color: AppColors.primary.withValues(alpha: 0.05),
                                        padding: const EdgeInsets.all(12),
                                        child: const Center(
                                          child: Icon(Icons.text_snippet_rounded, color: AppColors.primary, size: 40),
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (description.isNotEmpty)
                                            Text(
                                              description,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('dd MMM yyyy').format(item.createdAt.toLocal()),
                                            style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(LocaleKeys.memberSince.tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(
                                '${worker.createdAt.day}/${worker.createdAt.month}/${worker.createdAt.year}',
                                style: const TextStyle(
                                    color: AppColors.textMedium)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(LocaleKeys.reviews.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  if (_ratings.isEmpty)
                    Center(
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(LocaleKeys.noReviewsYet.tr(),
                                style: const TextStyle(
                                    color: AppColors.textLight))))
                  else
                    ..._ratings.map((r) => _buildReviewCard(r)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(detail.RatingModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                    r.raterName.isNotEmpty ? r.raterName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(r.raterName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13))),
              Text(DateFormat('dd MMM yyyy').format(r.createdAt.toLocal()),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
                5,
                (i) => Icon(
                      i < r.score
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: Colors.amber,
                    )),
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.comment,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMedium)),
          ],
        ],
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      );

  Widget _divider() => Container(width: 1, height: 48, color: AppColors.border);
}
