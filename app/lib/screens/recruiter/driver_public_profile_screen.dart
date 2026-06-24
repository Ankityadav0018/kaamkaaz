import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/driver_profile_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../l10n/locale_keys.g.dart';
import '../../utils/api_config.dart';

class DriverPublicProfileScreen extends ConsumerStatefulWidget {
  final String driverId;
  const DriverPublicProfileScreen({super.key, required this.driverId});

  @override
  ConsumerState<DriverPublicProfileScreen> createState() =>
      _DriverPublicProfileScreenState();
}

class _DriverPublicProfileScreenState
    extends ConsumerState<DriverPublicProfileScreen> {
  Map<String, dynamic>? _driver;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.get(
        '${ApiConfig.driverPublicProfile}/${widget.driverId}');
    if (mounted) {
      setState(() {
        _driver = res['data'];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_driver == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(LocaleKeys.driverNotFound.tr())),
      );
    }

    final driver = _driver!;
    final dp = DriverProfileModel.fromJson(
        driver['driverProfile'] as Map<String, dynamic>?);
    final name = driver['name'] as String? ?? '';
    final rating = (driver['rating']?['average'] ?? 0).toDouble();
    final ratingCount = driver['rating']?['count'] ?? 0;
    final completedJobs = driver['completedJobsCount'] ?? 0;
    final village = driver['village'] as String? ?? '';
    final passportUrl = dp.passportPhotoUrl;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.driving,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.driving,
                      AppColors.driving.withValues(alpha: 0.7)
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: passportUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: passportUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                  color: AppColors.inputBg,
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))),
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: AppColors.textLight),
                            )
                          : Center(
                              child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white))),
                    ),
                    const SizedBox(height: 12),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('✅ ${LocaleKeys.verifiedDriver.tr()}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (village.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('📍 $village',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13)),
                      ),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('⭐', rating.toStringAsFixed(1),
                            '${LocaleKeys.rating.tr()} ($ratingCount)'),
                        _divider(),
                        _stat('✅', '$completedJobs', LocaleKeys.jobsDone.tr()),
                        _divider(),
                        _stat('📅', '${dp.experienceYears}',
                            LocaleKeys.yrsExp.tr()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (dp.vehicleTypes.isNotEmpty)
                    _infoCard(
                      '🚘 ${LocaleKeys.vehicleTypes.tr()}',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dp.vehicleTypes
                            .map((vt) => Chip(
                                  label: Text(vt,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  backgroundColor:
                                      AppColors.driving.withValues(alpha: 0.08),
                                  side: BorderSide(
                                      color: AppColors.driving
                                          .withValues(alpha: 0.3)),
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (dp.languages.isNotEmpty)
                    _infoCard(
                      '🗣️ ${LocaleKeys.languages.tr()}',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dp.languages
                            .map((l) => Chip(
                                  label: Text(l,
                                      style: const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _infoCard(
                    '⚙️ ${LocaleKeys.preferences.tr()}',
                    child: Column(
                      children: [
                        _prefRow(
                            '✈️ ${LocaleKeys.outstationTrips.tr()}',
                            dp.willingToOutstation
                                ? LocaleKeys.available.tr()
                                : LocaleKeys.notAvailable.tr(),
                            dp.willingToOutstation
                                ? AppColors.success
                                : AppColors.textLight),
                        const Divider(height: 16),
                        _prefRow(
                            '🚘 ${LocaleKeys.ownVehicle.tr()}',
                            dp.hasOwnVehicle
                                ? '${dp.ownVehicleType} (${dp.ownVehicleRegNumber})'
                                : LocaleKeys.noOwnVehicle.tr(),
                            dp.hasOwnVehicle
                                ? AppColors.primary
                                : AppColors.textLight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_rounded,
                            color: AppColors.info, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            LocaleKeys.phoneRevealedAfterAccept.tr(),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String value, String label) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            Text(value,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textLight),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _divider() => Container(width: 1, height: 48, color: AppColors.border);

  Widget _infoCard(String title, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _prefRow(String label, String value, Color valueColor) => Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ],
      );
}
