import 'package:flutter_riverpod/flutter_riverpod.dart';

class JobFilters {
  final String? category;
  final double minWage;
  final double maxWage;
  final int? radiusKm; // null = no explicit filter, backend defaults to 50 km nearest-first
  final bool urgentOnly;
  final String? keyword;
  final String? jobType;
  final bool exploreMode;

  JobFilters({
    this.category,
    this.minWage = 0,
    this.maxWage = 2000,
    this.radiusKm,  // null by default — no visual selection, uses backend 50 km
    this.urgentOnly = false,
    this.keyword,
    this.jobType,
    this.exploreMode = false,
  });

  JobFilters copyWith({
    String? category,
    double? minWage,
    double? maxWage,
    int? radiusKm,
    bool? urgentOnly,
    String? keyword,
    String? jobType,
    bool? exploreMode,
    bool clearCategory = false,
    bool clearKeyword = false,
    bool clearJobType = false,
    bool clearRadius = false,
  }) {
    return JobFilters(
      category: clearCategory ? null : (category ?? this.category),
      minWage: minWage ?? this.minWage,
      maxWage: maxWage ?? this.maxWage,
      radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
      urgentOnly: urgentOnly ?? this.urgentOnly,
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      jobType: clearJobType ? null : (jobType ?? this.jobType),
      exploreMode: exploreMode ?? this.exploreMode,
    );
  }

  bool get isDefault =>
      category == null &&
      minWage == 0 &&
      maxWage == 2000 &&
      radiusKm == null &&
      urgentOnly == false &&
      keyword == null &&
      jobType == null &&
      exploreMode == false;
}

class JobFilterNotifier extends StateNotifier<JobFilters> {
  JobFilterNotifier() : super(JobFilters());

  void setCategory(String? category) {
    state = state.copyWith(category: category, clearCategory: category == null);
  }

  void setWageRange(double min, double max) {
    state = state.copyWith(minWage: min, maxWage: max);
  }

  void setRadius(int? radius) {
    state = state.copyWith(radiusKm: radius, clearRadius: radius == null);
  }

  void toggleUrgentOnly() {
    state = state.copyWith(urgentOnly: !state.urgentOnly);
  }

  void setKeyword(String? keyword) {
    state = state.copyWith(
        keyword: keyword, clearKeyword: keyword == null || keyword.isEmpty);
  }

  void setJobType(String? jobType) {
    state = state.copyWith(jobType: jobType, clearJobType: jobType == null);
  }

  void setExploreMode(bool value) {
    state = state.copyWith(exploreMode: value);
  }

  void reset() {
    state = JobFilters();
  }
}

final jobFilterProvider =
    StateNotifierProvider<JobFilterNotifier, JobFilters>((ref) {
  return JobFilterNotifier();
});
