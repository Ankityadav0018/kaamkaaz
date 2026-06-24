import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/application_provider.dart';
import '../../providers/rating_provider.dart';
import '../../services/job_service.dart';
import '../../providers/connectivity_provider.dart';
import '../../models/job_model.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';
import '../../utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../l10n/locale_keys.g.dart';
import '../../widgets/rating_dialog.dart';
import '../../widgets/dispute_status_banner.dart';
import '../shared/raise_dispute_screen.dart';
import '../../services/share_service.dart';
import '../../widgets/brand_logo.dart';
import '../../utils/app_utils.dart';
import '../../services/api_service.dart';
import '../../utils/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kaamkaaz/widgets/voice_text_field.dart';
class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  JobModel? _job;
  bool _isLoading = true;
  bool _hasApplied = false;
  final _messageCtrl = TextEditingController();
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  bool _isSharingLocation = false;
  bool _hasRated = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final job = await JobService.getJobById(widget.jobId);
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _job = job;
        _isLoading = false;
        _hasApplied = job?.isApplied ?? false;
        _isCheckedIn = prefs.getBool('checkIn_${widget.jobId}') ?? false;
        _isCheckedOut = prefs.getBool('checkOut_${widget.jobId}') ?? false;
        _isSharingLocation = prefs.getBool('live_loc_${widget.jobId}') ?? false;
        
        if (job != null && (job.status == 'assigned' || job.status == 'accepted')) {
          NotificationService.scheduleJobReminder(job.id, job.title, job.location.address, job.dateTime);
        }
      });
    }
  }

  Future<void> _apply() async {
    if (_hasApplied) return;

    final user = ref.read(authProvider).user;

    if (user?.kycStatus != 'approved') {
      _showSnack(LocaleKeys.kycNotApprovedApplied.tr(), AppColors.warning);
      return;
    }

    if (_job?.jobType == 'driver') {
      if (user?.workerType != 'driver') {
        _showSnack(LocaleKeys.onlyDriversCanApply.tr(), AppColors.danger);
        return;
      }
      if (user?.driverProfile?.kycStatus != 'verified') {
        _showSnack(LocaleKeys.driverKycNotVerified.tr(), AppColors.warning);
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleKeys.applyForJob.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_job?.title ?? '',
                style: const TextStyle(color: AppColors.textMedium)),
            const SizedBox(height: 16),
            VoiceTextField(
              controller: _messageCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: LocaleKeys.writeMessageHint.tr(),
                filled: true,
                fillColor: AppColors.inputBg,
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final result =
                      await ref.read(applicationProvider.notifier).apply(
                            widget.jobId,
                            message: _messageCtrl.text.trim(),
                          );
                  if (!mounted) return;
                  if (result['success'] == true) {
                    setState(() => _hasApplied = true);
                    _showSnack(
                        LocaleKeys.appliedSuccessfully.tr(), AppColors.success);
                  } else {
                    _showSnack(
                        result['message'] ?? LocaleKeys.failedToApply.tr(),
                        AppColors.danger);
                  }
                },
                child: Text(LocaleKeys.apply.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    AppUtils.showTopSnackBar(context, msg, isError: color == AppColors.danger);
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = context.locale.languageCode == 'hi';

    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_job == null) {
      return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(LocaleKeys.jobNotFound.tr())));
    }

    final job = _job!;
    final catColor = AppColors.getCategoryColor(job.category);
    final currentUser = ref.watch(authProvider).user;
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              backgroundColor: catColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground
                ],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (job.images.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: job.images[0],
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              catColor.withValues(alpha: 0.8),
                              catColor.withValues(alpha: 0.5),
                              catColor.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                    // Dark overlay for text readability if image exists
                    if (job.images.isNotEmpty)
                      Container(color: Colors.black.withValues(alpha: 0.4)),
                    
                    if (job.images.isEmpty)
                      Center(
                        child: Hero(
                          tag: 'job_icon_${job.id}',
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10))
                              ],
                            ),
                            child: AppColors.getCategoryEmoji(job.category) == 'logo'
                                ? const BrandLogo(size: 64, borderRadius: 16)
                                : Icon(Icons.work_outline_rounded,
                                    size: 56, color: catColor),
                          ),
                        ),
                      ),
                    
                    if (job.isUrgent)
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.danger.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(LocaleKeys.urgent.tr().toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.15),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 18),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.report_problem_rounded, color: Colors.white, size: 18),
                  tooltip: 'reportFakeJobTooltip'.tr(),
                  onPressed: () => _handleFakeJobReport(),
                ),
                if (_job?.assignedWorkerId == currentUser?.id || _job?.status == 'completed')
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.15),
                      child: IconButton(
                        icon: const Icon(Icons.group_rounded, color: Colors.white, size: 18),
                        onPressed: () => context.push('/chat/group/${job.id}'),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.15),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.white, size: 18),
                      onPressed: () => ShareService.shareJobOnWhatsApp(job.id),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  decoration: const BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (job.hasDispute) const DisputeStatusBanner(),
                      if (job.hasDispute) const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(job.title,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color:
                                              catColor.withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: catColor.withValues(
                                                  alpha: 0.2))),
                                      child: Text(job.category.toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: catColor,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 8),
                                    if (job.formattedDistance.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.near_me_rounded,
                                              size: 13,
                                              color: AppColors.textLight),
                                          const SizedBox(width: 4),
                                          Text(job.formattedDistance,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textLight,
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.success
                                        .withValues(alpha: 0.1))),
                            child: Column(
                              children: [
                                Text('₹${job.wage}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success)),
                                Text(
                                    _job!.wageType == 'daily'
                                        ? LocaleKeys.perDay.tr()
                                        : LocaleKeys.fixed.tr(),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(LocaleKeys.jobDetails.tr(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.4,
                        children: [
                          _detailCard(
                              Icons.calendar_today_rounded,
                              LocaleKeys.startDate.tr(),
                              DateFormat('dd MMM').format(job.dateTime.toLocal()),
                              Colors.orange.shade700),
                          _detailCard(
                              Icons.access_time_rounded,
                              LocaleKeys.time.tr(),
                              DateFormat('hh:mm a').format(job.dateTime.toLocal()),
                              Colors.blue.shade700),
                          _detailCard(
                              Icons.timer_rounded,
                              LocaleKeys.duration.tr(),
                              job.durationText,
                              Colors.purple.shade700),
                          _detailCard(
                              Icons.group_rounded,
                              'Workers Needed',
                              job.maxWorkers.toString(),
                              Colors.teal.shade700),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _locationCard(job),
                      const SizedBox(height: 32),
                      if (job.jobType == 'driver' &&
                          job.driverRequirements != null) ...[
                        _sectionTitle(LocaleKeys.driverRequirements.tr()),
                        _driverReqCard(job),
                        const SizedBox(height: 32),
                      ],
                      _sectionTitle(LocaleKeys.jobDesc.tr()),
                      Text(job.description,
                          style: const TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 15,
                              height: 1.6)),
                      if (job.images.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _sectionTitle(LocaleKeys.sitePhotos.tr()),
                        _buildImageGallery(job),
                      ],
                      if (job.requiredSkills.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _sectionTitle(LocaleKeys.requiredSkills.tr()),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: job.requiredSkills
                              .map((sk) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Text(sk,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _sectionTitle(LocaleKeys.postedBy.tr()),
                      if (job.recruiter != null) _recruiterCard(job, isOnline),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
        ),
        child: _buildBottomAction(currentUser, isHindi, isOnline),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );

  Widget _detailCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard(JobModel job) {
    return GestureDetector(
      onTap: () async {
        final lat = job.location.coordinates[1];
        final lng = job.location.coordinates[0];
        final url = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(LocaleKeys.location.tr(),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                      job.location.address.isNotEmpty
                          ? job.location.address
                          : LocaleKeys.addressNotSpecified.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _driverReqCard(JobModel job) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.driving.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.driving.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _driverReqRow(
              Icons.directions_car_rounded,
              LocaleKeys.requiredVehicle.tr(),
              job.driverRequirements!['vehicleType'] ?? 'Any'),
          const Divider(height: 24),
          _driverReqRow(
              Icons.vpn_key_rounded,
              LocaleKeys.mustHaveOwnVehicle.tr(),
              job.driverRequirements!['mustHaveOwnVehicle'] == true
                  ? LocaleKeys.yesRequired.tr()
                  : LocaleKeys.noProvidedByRecruiter.tr()),
          const Divider(height: 24),
          _driverReqRow(
              Icons.explore_rounded,
              LocaleKeys.outstationRequired.tr(),
              job.driverRequirements!['outstationRequired'] == true
                  ? LocaleKeys.yesRequired.tr()
                  : LocaleKeys.localOnly.tr()),
        ],
      ),
    );
  }

  Widget _driverReqRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.driving),
          const SizedBox(width: 12),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textMedium)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.driving)),
        ],
      );

  Widget _buildImageGallery(JobModel job) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: job.images.length,
        itemBuilder: (context, i) {
          final imgData = job.images[i];
          ImageProvider? provider;
          if (imgData.startsWith('http')) {
            provider = NetworkImage(imgData);
          } else if (imgData.contains('base64,')) {
            final bytes = base64Decode(imgData.split('base64,').last);
            provider = MemoryImage(bytes);
          }
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              image: provider != null
                  ? DecorationImage(image: provider, fit: BoxFit.cover)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _recruiterCard(JobModel job, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: job.recruiter!.profileImage.isNotEmpty
                ? NetworkImage(job.recruiter!.profileImage)
                : null,
            child: job.recruiter!.profileImage.isEmpty
                ? Text(
                    job.recruiter!.name.isNotEmpty
                        ? job.recruiter!.name[0]
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.recruiter!.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppColors.accent),
                    Text(' ${job.recruiter!.rating.average.toStringAsFixed(1)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (job.recruiter!.companyName.isNotEmpty)
                      Flexible(
                          child: Text('• ${job.recruiter!.companyName}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textLight),
                              overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isOnline ? () =>
                context.push('/chat/${job.id}/${job.recruiter!.id}') : null,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: isOnline ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_rounded,
                  color: isOnline ? AppColors.primary : Colors.grey, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(UserModel? currentUser, bool isHindi, bool isOnline) {
    if (_job == null) return const SizedBox();
    final isAssigned = _job!.assignedWorkerId == currentUser?.id;

    if (_job!.status == 'completed' && isAssigned) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_hasRated)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RatingDialog(
                      title: LocaleKeys.rateRecruiter.tr(),
                      subtitle: LocaleKeys.rateRecruiterSubtitle.tr(namedArgs: {
                        'name': _job!.recruiter?.name ?? "this recruiter"
                      }),
                      onSubmit: (score, comment) async {
                        final result =
                            await ref.read(ratingProvider.notifier).submitRating(
                                  jobId: _job!.id,
                                  score: score,
                                  comment: comment,
                                );
                        if (mounted) {
                          if (result['success'] == true) {
                            setState(() => _hasRated = true);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppColors.success),
                                    const SizedBox(width: 8),
                                    Text(LocaleKeys.ratingSubmittedTitle.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: Text(LocaleKeys.thankYouRatingMsg.tr()),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  )
                                ],
                              ),
                            );
                            _load(); // Reload job details to update rating in UI
                          } else {
                            _showSnack(result['message'] ?? LocaleKeys.error.tr(),
                                AppColors.danger);
                          }
                        }
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.star_rounded),
                label: Text(
                  LocaleKeys.rateRecruiter.tr().toUpperCase(),
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (!_job!.hasDispute) ...[
            if (!_hasRated) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RaiseDisputeScreen(jobId: _job!.id),
                    ),
                  );
                  if (result == true) _load();
                },
                icon: const Icon(Icons.gavel_rounded, color: Colors.red),
                label: Text(
                  LocaleKeys.raiseDispute.tr().toUpperCase(),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ],
      );
    }

    if (isAssigned && (_job!.status == 'assigned' || _job!.status == 'accepted')) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckedOut 
                        ? null 
                        : () => _isCheckedIn ? _handleCheckOut() : _handleCheckIn(),
                    icon: Icon(_isCheckedIn ? Icons.logout_rounded : Icons.login_rounded),
                    label: Text((_isCheckedOut ? "Work Completed" : _isCheckedIn ? "Check-out" : "Check-in").toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: _isCheckedOut ? Colors.grey : AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isCheckedOut ? null : _toggleLocationSharing,
                    icon: Icon(Icons.my_location_rounded, color: _isSharingLocation ? Colors.red : AppColors.primary),
                    label: Text((_isSharingLocation ? "Stop Live" : "Share Live").toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: _isSharingLocation ? Colors.red : AppColors.primary)),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: _isSharingLocation ? Colors.red : AppColors.primary)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final lat = _job!.location.coordinates[1];
                final lng = _job!.location.coordinates[0];
                final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.directions_rounded),
              label: Text(LocaleKeys.navigate.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
          ),
        ],
      );
    }

    if (_job!.status != 'open') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(LocaleKeys.jobIs.tr(args: [_job!.status.toUpperCase()]),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textLight,
                fontSize: 16)),
      );
    }

    if (_hasApplied) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Text(
                LocaleKeys.applied
                    .tr()
                    .toUpperCase()
                    .replaceAll('✓', '')
                    .trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                    fontSize: 16)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: isOnline ? _apply : null,
        icon: Icon(isOnline ? Icons.send_rounded : Icons.wifi_off_rounded, size: 24),
        label: Text(
          isOnline ? LocaleKeys.apply.tr().toUpperCase() : "OFFLINE MODE",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isOnline ? AppColors.success : Colors.grey,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  void _handleFakeJobReport() {
    final currentUser = ref.read(authProvider).user;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('reportJob'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['reportFakeJob'.tr(), 'reportWrongInfo'.tr(), 'reportSpam'.tr(), 'reportInappropriate'.tr()].map((r) => ListTile(
                  title: Text(r),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await ApiService.post(ApiConfig.reports, {
                        'title': 'Job Report: $r',
                        'description': 'User reported job ID: ${widget.jobId}. Reason: $r',
                        'jobId': widget.jobId,
                        'reason': r,
                        if (_job != null) ...{
                          'reportedUserId': _job!.recruiterId,
                          'jobTitle': _job!.title,
                          'recruiterName': _job!.recruiter?.name ?? 'Unknown',
                        },
                        if (currentUser != null) 'workerName': currentUser.name,
                      });
                      _showSnack('Your report has been sent to our team. We will take action soon. Thank you.', AppColors.success);
                    } catch (e) {
                      _showSnack('Error reporting job: $e', AppColors.danger);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    final pos = await Geolocator.getCurrentPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkIn_${widget.jobId}', true);
    await prefs.setString('checkInTime_${widget.jobId}', DateTime.now().toIso8601String());
    
    // Auto-stop location sharing if active
    if (_isSharingLocation) _toggleLocationSharing();
    
    setState(() => _isCheckedIn = true);
    _showSnack('checkInSuccess'.tr(), AppColors.success);
    
    // Broadcast check-in to Recruiter
    Supabase.instance.client.channel('job_updates_${widget.jobId}').sendBroadcastMessage(
        event: 'check_in', payload: {'lat': pos.latitude, 'lng': pos.longitude, 'timestamp': DateTime.now().toIso8601String()});
  }

  Future<void> _handleCheckOut() async {
    final pos = await Geolocator.getCurrentPosition();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checkOut_${widget.jobId}', true);
    final inTimeStr = prefs.getString('checkInTime_${widget.jobId}');
    final duration = inTimeStr != null ? DateTime.now().difference(DateTime.parse(inTimeStr)).inHours : 0;
    
    setState(() => _isCheckedOut = true);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('workSummary'.tr()),
        content: Text('checkOutSuccessMsg'.tr(args: [duration.toString()])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('close'.tr()))
        ],
      )
    );
    
    Supabase.instance.client.channel('job_updates_${widget.jobId}').sendBroadcastMessage(
        event: 'check_out', payload: {'lat': pos.latitude, 'lng': pos.longitude, 'timestamp': DateTime.now().toIso8601String()});
  }

  Future<void> _toggleLocationSharing() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isSharingLocation) {
      _positionStream?.cancel();
      await prefs.setBool('live_loc_${widget.jobId}', false);
      setState(() => _isSharingLocation = false);
    } else {
      final pos = await LocationService.getCurrentLocation(context: context);
      if (pos == null) return;
      setState(() => _isSharingLocation = true);
      await prefs.setBool('live_loc_${widget.jobId}', true);
      
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
      ).listen((Position position) {
        Supabase.instance.client.channel('live_loc_${widget.jobId}').sendBroadcastMessage(
          event: 'location_update',
          payload: {'lat': position.latitude, 'lng': position.longitude, 'workerId': ref.read(authProvider).user?.id}
        );
      });
      _showSnack("Live location sharing started", AppColors.success);
    }
  }
}
