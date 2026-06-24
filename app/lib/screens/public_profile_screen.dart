import '../l10n/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/api_config.dart';
import '../models/rating_model.dart' as detail;

import '../utils/constants.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  UserModel? _user;
  List<detail.RatingModel> _ratings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res =
          await ApiService.get('${ApiConfig.publicProfile}/${widget.userId}');
      if (res['success'] == true && res['data'] != null) {
        final ratingsRes =
            await ApiService.get('${ApiConfig.userRatings}/${widget.userId}');
        if (mounted) {
          setState(() {
            _user = UserModel.fromJson(res['data']);
            if (ratingsRes['success'] == true && ratingsRes['data'] != null) {
              _ratings = (ratingsRes['data'] as List)
                  .map((r) => detail.RatingModel.fromJson(r))
                  .toList();
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: AppColors.bgLight,
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.profileNotFoundTitle.tr())),
        body: Center(child: Text(LocaleKeys.userDoesNotExist.tr())),
      );
    }

    final u = _user!;
    final remainingSkills = u.skills
        .where((s) => !u.verifiedSkills.any((vs) => vs.toLowerCase() == s.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title:
            Text(u.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: u.profileImage.isNotEmpty
                  ? CachedNetworkImageProvider(u.profileImage)
                  : null,
              child: u.profileImage.isEmpty
                  ? Text(u.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 40,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(u.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (u.role.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(u.role.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            const SizedBox(height: 24),
            _buildStatCard(u),
            const SizedBox(height: 24),
            if (u.role == 'worker' && (u.skills.isNotEmpty || u.verifiedSkills.isNotEmpty)) ...[
              if (u.verifiedSkills.isNotEmpty) ...[
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(LocaleKeys.skillBadges.tr(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: u.verifiedSkills
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
                const SizedBox(height: 24),
              ],
              if (remainingSkills.isNotEmpty) ...[
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(LocaleKeys.skillsTitle.tr(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: remainingSkills
                        .map((s) => Chip(
                              label: Text(s,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 12)),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
            if (u.companyName.isNotEmpty) ...[
              _buildInfoRow(Icons.business_rounded, 'Company', u.companyName),
              const SizedBox(height: 12),
            ],
            if (u.village.isNotEmpty) ...[
              _buildInfoRow(
                  Icons.location_city_rounded, 'Village/City', u.village),
              const SizedBox(height: 12),
            ],
            if (u.location.address.isNotEmpty) ...[
              _buildInfoRow(
                  Icons.location_on_rounded, 'Address', u.location.address),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),

            // Previous Work / About Section
            if (u.role == 'worker' && u.portfolio.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'previousWork'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: u.portfolio.length,
                  itemBuilder: (context, index) {
                    final item = u.portfolio[index];
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
              const SizedBox(height: 24),
            ],

            Align(
                alignment: Alignment.centerLeft,
                child: Text(LocaleKeys.reviewsTitle.tr(),
                    style:
                        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),
            if (_ratings.isEmpty)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(LocaleKeys.noReviewsYetAlt.tr(),
                          style: const TextStyle(color: AppColors.textLight))))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ratings.length,
                itemBuilder: (context, index) =>
                    _buildReviewCard(_ratings[index]),
              ),
            const SizedBox(height: 40),
          ],
        ),
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
                child: Text(r.raterName[0].toUpperCase(),
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

  Widget _buildStatCard(UserModel u) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(Icons.star_rounded, u.rating.average.toStringAsFixed(1),
              'Rating', Colors.amber),
          Container(width: 1, height: 40, color: AppColors.border),
          _statItem(Icons.task_alt_rounded, '${u.completedJobsCount}', 'Jobs',
              AppColors.success),
          if (u.role == 'worker') ...[
            Container(width: 1, height: 40, color: AppColors.border),
            _statItem(Icons.history_rounded, '${u.experienceDays}',
                'Exp (Days)', AppColors.primary),
          ],
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String val, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Flexible(
                  child: Text(val,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
