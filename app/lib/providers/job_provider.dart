import '../services/job_service.dart';
import '../services/cache_service.dart';
import '../services/widget_service.dart';
import '../models/job_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JobState {
  final List<JobModel> nearbyJobs;
  final List<JobModel> myJobs;
  final JobModel? selectedJob;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const JobState({
    this.nearbyJobs = const [],
    this.myJobs = const [],
    this.selectedJob,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  JobState copyWith({
    List<JobModel>? nearbyJobs,
    List<JobModel>? myJobs,
    JobModel? selectedJob,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      JobState(
        nearbyJobs: nearbyJobs ?? this.nearbyJobs,
        myJobs: myJobs ?? this.myJobs,
        selectedJob: selectedJob ?? this.selectedJob,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class JobNotifier extends StateNotifier<JobState> {
  JobNotifier() : super(const JobState());

  Future<void> fetchNearbyJobs({
    double? lat,
    double? lng,
    String? category,
    int? radius,
    double? minWage,
    double? maxWage,
    bool? urgentOnly,
    String? keyword,
    String? jobType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final jobs = await JobService.getNearbyJobs(
        lat: lat,
        lng: lng,
        category: category,
        radius: radius,
        minWage: minWage,
        maxWage: maxWage,
        urgentOnly: urgentOnly,
        keyword: keyword,
        jobType: jobType,
      );
      state = state.copyWith(
          nearbyJobs: jobs, isLoading: false, lastUpdated: DateTime.now());

      // Save to cache
      await CacheService.saveJobList(jobs.map((j) => j.toJson()).toList());
      
      // Update Android Widget
      await WidgetService.updateWidgetWithJobs(jobs);
    } catch (e) {
      // On error, try to load from cache
      final cached = await CacheService.getJobList();
      if (cached != null) {
        final cachedJobs = (cached['data'] as List)
            .map((json) => JobModel.fromJson(json))
            .toList();
        state = state.copyWith(
          nearbyJobs: cachedJobs,
          isLoading: false,
          error: e.toString(),
          lastUpdated: cached['cachedAt'],
        );
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> fetchMyJobs({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final jobs = await JobService.getMyJobs(status: status);
      state = state.copyWith(myJobs: jobs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>> postJob(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    final result = await JobService.postJob(data);
    state = state.copyWith(isLoading: false);
    return result;
  }

  Future<Map<String, dynamic>> updateJob(String jobId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    final result = await JobService.updateJob(jobId, data);
    state = state.copyWith(isLoading: false);
    return result;
  }

  Future<Map<String, dynamic>> updateJobStatus(
      String jobId, String status) async {
    final result = await JobService.updateJobStatus(jobId, status);
    if (result['success'] == true) {
      await fetchMyJobs();
    }
    return result;
  }

  void markJobApplied(String jobId) {
    state = state.copyWith(
      nearbyJobs: state.nearbyJobs
          .map((j) => j.id == jobId
              ? JobModel.fromJson({...j.toJson(), 'isApplied': true})
              : j)
          .toList(),
    );
  }
}

final jobProvider =
    StateNotifierProvider<JobNotifier, JobState>((ref) => JobNotifier());

extension JobModelJson on JobModel {
  Map<String, dynamic>? toJson() => {
        '_id': id,
        'title': title,
        'description': description,
        'category': category,
        'requiredSkills': requiredSkills,
        'wage': wage,
        'wageType': wageType,
        'maxWorkers': maxWorkers,
        'location': location.toJson(),
        'dateTime': dateTime.toIso8601String(),
        'durationValue': durationValue,
        'durationUnit': durationUnit,
        'recruiterId': recruiterId,
        'status': status,
        'applicantCount': applicantCount,
        'isUrgent': isUrgent,
        'distance': distance,
        'isApplied': isApplied,
        'createdAt': createdAt.toIso8601String(),
      };
}
