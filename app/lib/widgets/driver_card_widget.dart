import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/app_colors.dart';
import '../l10n/locale_keys.g.dart';

class DriverCardWidget extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onTap;

  const DriverCardWidget(
      {super.key, required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dp = driver['driverProfile'] as Map<String, dynamic>? ?? {};
    final vehicleTypes = List<String>.from(dp['vehicleTypes'] ?? []);
    final expYears = dp['experienceYears'] ?? 0;
    final outstation = dp['willingToOutstation'] == true;
    final rating = (driver['rating']?['average'] ?? 0).toDouble();
    final passportUrl = dp['passportPhotoUrl'] as String? ?? '';
    final distance = driver['distance'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: passportUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: passportUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      memCacheHeight: 200,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, size: 24),
                    )
                  : Center(
                      child: Text(
                        (driver['name'] as String? ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(driver['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('✅ ${LocaleKeys.verified.tr()}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.accent),
                          Text(' ${rating.toStringAsFixed(1)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_rounded,
                              size: 14, color: AppColors.textLight),
                          Text(' $expYears ${LocaleKeys.yrsExpShort.tr()}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMedium)),
                        ],
                      ),
                      if (distance != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: AppColors.primary),
                            Text(' ${distance.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.primary)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...vehicleTypes.take(3).map((vt) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.driving.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(vt,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.driving,
                                    fontWeight: FontWeight.w600)),
                          )),
                      if (outstation)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('✈️ ${LocaleKeys.outstation.tr()}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
