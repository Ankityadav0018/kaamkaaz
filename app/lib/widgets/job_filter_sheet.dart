import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/job_filter_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/brand_logo.dart';
import '../l10n/locale_keys.g.dart';

import '../models/user_model.dart';

class JobFilterSheet extends ConsumerStatefulWidget {
  final UserModel? currentUser;
  const JobFilterSheet({super.key, this.currentUser});

  @override
  ConsumerState<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends ConsumerState<JobFilterSheet> {
  late String? _selectedCategory;
  late RangeValues _wageRange;
  int? _selectedRadius; // null = no explicit selection
  late bool _urgentOnly;
  late String? _jobType;
  late bool _exploreMode;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'plumber', 'label': LocaleKeys.filter_plumber.tr(), 'icon': Icons.plumbing_rounded},
    {
      'id': 'electrician',
      'label': LocaleKeys.filter_electrician.tr(),
      'icon': Icons.electrical_services_rounded
    },
    {'id': 'carpenter', 'label': LocaleKeys.filter_carpenter.tr(), 'icon': Icons.carpenter_rounded},
    {'id': 'painter', 'label': LocaleKeys.filter_painter.tr(), 'icon': Icons.format_paint_rounded},
    {
      'id': 'cleaner',
      'label': LocaleKeys.filter_cleaner.tr(),
      'icon': Icons.cleaning_services_rounded
    },
    {'id': 'driver', 'label': LocaleKeys.filter_driver.tr(), 'icon': Icons.directions_car_rounded},
    {
      'id': 'helper',
      'label': LocaleKeys.filter_helper.tr(),
      'icon': Icons.local_shipping_rounded
    },
    {
      'id': 'security',
      'label': LocaleKeys.filter_security.tr(),
      'icon': Icons.security_rounded
    },
    {'id': 'cook', 'label': LocaleKeys.filter_cook.tr(), 'icon': Icons.restaurant_rounded},
    {
      'id': 'mason',
      'label': LocaleKeys.filter_mason.tr(),
      'icon': Icons.construction_rounded
    },
    {'id': 'welder', 'label': LocaleKeys.filter_welder.tr(), 'icon': Icons.flash_on_rounded},
    {'id': 'other', 'label': LocaleKeys.filter_other.tr(), 'icon': Icons.work_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(jobFilterProvider);
    _selectedCategory = currentFilters.category;
    _wageRange = RangeValues(currentFilters.minWage, currentFilters.maxWage);
    _selectedRadius = currentFilters.radiusKm; // may be null
    _urgentOnly = currentFilters.urgentOnly;
    _jobType = currentFilters.jobType;
    _exploreMode = currentFilters.exploreMode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(LocaleKeys.filterTitle.tr(),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _sectionHeader(LocaleKeys.category.tr()),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _categoryChip(null, LocaleKeys.all.tr(), null),
                      ..._categories.map((c) =>
                          _categoryChip(c['id'], c['label']!, c['icon']!)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader(LocaleKeys.dailyWage.tr()),
                const SizedBox(height: 8),
                Text(
                    '₹${_wageRange.start.round()} — ₹${_wageRange.end.round()}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.primary)),
                RangeSlider(
                  values: _wageRange,
                  min: 0,
                  max: 2000,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _wageRange = val);
                  },
                ),
                const SizedBox(height: 24),
                _sectionHeader(LocaleKeys.distanceLabel.tr()),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...[5, 10, 15, 25, 50].map((r) => _radiusOption(r)),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.explore_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(LocaleKeys.exploreMode.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(LocaleKeys.exploreModeSub.tr(), style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _exploreMode,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _exploreMode = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _sectionHeader(LocaleKeys.jobType.tr()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _choiceChip(LocaleKeys.allJobs.tr(), _jobType == null, () {
                      setState(() => _jobType = null);
                    }),
                    // Only driver-registered workers can filter by driver jobs
                    if (widget.currentUser?.isDriver == true) ...[
                      const SizedBox(width: 12),
                      _choiceChip(
                          LocaleKeys.driverJobsOnly.tr(), _jobType == 'driver',
                          () {
                        setState(() => _jobType = 'driver');
                      }),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                _sectionHeader(LocaleKeys.urgentOnly.tr()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _choiceChip(LocaleKeys.allJobs.tr(), !_urgentOnly, () {
                      setState(() => _urgentOnly = false);
                    }),
                    const SizedBox(width: 12),
                    _choiceChip(LocaleKeys.urgentOnly.tr(), _urgentOnly, () {
                      setState(() => _urgentOnly = true);
                    }),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(jobFilterProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text(LocaleKeys.resetFilters.tr()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final notifier = ref.read(jobFilterProvider.notifier);
                      notifier.setCategory(_selectedCategory);
                      notifier.setWageRange(_wageRange.start, _wageRange.end);
                      notifier.setRadius(_selectedRadius); // null clears the filter
                      notifier.setJobType(_jobType);
                      if (_urgentOnly !=
                          ref.read(jobFilterProvider).urgentOnly) {
                        notifier.toggleUrgentOnly();
                      }
                      if (_exploreMode != ref.read(jobFilterProvider).exploreMode) {
                        notifier.setExploreMode(_exploreMode);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(LocaleKeys.applyFilters.tr()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textMedium));

  Widget _categoryChip(String? id, String label, dynamic iconData) {
    final isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = id);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            if (id == null)
              const BrandLogo(size: 16, borderRadius: 4)
            else
              Icon(iconData as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textMedium,
                )),
          ],
        ),
      ),
    );
  }

  Widget _radiusOption(int km) {
    final isSelected = _selectedRadius == km && !_exploreMode;
    return GestureDetector(
      onTap: _exploreMode
          ? null
          : () {
              setState(() {
                // Tap selected button again to deselect (clear)
                _selectedRadius = (_selectedRadius == km) ? null : km;
              });
            },
      child: Column(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: _exploreMode
                  ? Colors.grey.shade200
                  : (isSelected ? AppColors.primary : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(
                  color: _exploreMode
                      ? Colors.grey.shade300
                      : (isSelected ? AppColors.primary : AppColors.border)),
            ),
            child: Center(
              child: Text('${km}km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _exploreMode
                        ? Colors.grey.shade500
                        : (isSelected ? Colors.white : AppColors.textDark),
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textDark,
            )),
      ),
    );
  }
}
