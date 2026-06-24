import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application_model.dart';
import '../models/user_model.dart';
import '../services/application_service.dart';

class ApplicationState {
  final List<ApplicationModel> myApplications;
  final List<ApplicationModel> recruiterApplications;
  final List<ApplicationModel> jobApplications;
  final UserModel? acceptedWorker;
  final bool isLoading;
  final String? error;

  const ApplicationState({
    this.myApplications = const [],
    this.recruiterApplications = const [],
    this.jobApplications = const [],
    this.acceptedWorker,
    this.isLoading = false,
    this.error,
  });

  ApplicationState copyWith({
    List<ApplicationModel>? myApplications,
    List<ApplicationModel>? recruiterApplications,
    List<ApplicationModel>? jobApplications,
    UserModel? acceptedWorker,
    bool? isLoading,
    String? error,
  }) =>
      ApplicationState(
        myApplications: myApplications ?? this.myApplications,
        recruiterApplications: recruiterApplications ?? this.recruiterApplications,
        jobApplications: jobApplications ?? this.jobApplications,
        acceptedWorker: acceptedWorker ?? this.acceptedWorker,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ApplicationNotifier extends StateNotifier<ApplicationState> {
  ApplicationNotifier() : super(const ApplicationState());

  Future<void> fetchMyApplications({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apps = await ApplicationService.getMyApplications(status: status);
      state = state.copyWith(myApplications: apps, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchRecruiterApplications({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apps = await ApplicationService.getRecruiterApplications(status: status);
      state = state.copyWith(recruiterApplications: apps, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchJobApplications(String jobId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final apps = await ApplicationService.getJobApplications(jobId);
      state = state.copyWith(jobApplications: apps, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>> apply(String jobId, {String? message}) async {
    state = state.copyWith(isLoading: true);
    final result =
        await ApplicationService.applyForJob(jobId, message: message);
    state = state.copyWith(isLoading: false);
    return result;
  }

  Future<Map<String, dynamic>> accept(String applicationId) async {
    state = state.copyWith(isLoading: true);
    final result = await ApplicationService.acceptApplication(applicationId);
    if (result['success'] == true) {
      state = state.copyWith(
        acceptedWorker: result['worker'],
        jobApplications: state.jobApplications.map((a) {
          if (a.id == applicationId) {
            return ApplicationModel.fromJson({
              ...{},
              '_id': a.id,
              'jobId': a.jobId,
              'workerId': a.workerId,
              'status': 'accepted',
              'contactRevealed': true,
              'message': a.message,
              'createdAt': a.createdAt.toIso8601String()
            });
          }
          return ApplicationModel.fromJson({
            '_id': a.id,
            'jobId': a.jobId,
            'workerId': a.workerId,
            'status': a.status == 'applied' ? 'rejected' : a.status,
            'contactRevealed': a.contactRevealed,
            'message': a.message,
            'createdAt': a.createdAt.toIso8601String()
          });
        }).toList(),
        recruiterApplications: state.recruiterApplications.map((a) {
          if (a.id == applicationId) {
            return ApplicationModel.fromJson({
              ...{},
              '_id': a.id,
              'jobId': a.jobId,
              'workerId': a.workerId,
              'status': 'accepted',
              'contactRevealed': true,
              'message': a.message,
              'createdAt': a.createdAt.toIso8601String()
            });
          }
          if (a.jobId == state.jobApplications.firstWhere((x) => x.id == applicationId, orElse: () => state.recruiterApplications.firstWhere((y) => y.id == applicationId)).jobId && a.status == 'applied') {
            return ApplicationModel.fromJson({
              '_id': a.id,
              'jobId': a.jobId,
              'workerId': a.workerId,
              'status': 'rejected',
              'contactRevealed': a.contactRevealed,
              'message': a.message,
              'createdAt': a.createdAt.toIso8601String()
            });
          }
          return a;
        }).toList(),
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
    return result;
  }

  Future<Map<String, dynamic>> reject(String applicationId) async {
    state = state.copyWith(isLoading: true);
    final result = await ApplicationService.rejectApplication(applicationId);
    if (result['success'] == true) {
      if (state.jobApplications.isNotEmpty) {
        await fetchJobApplications(
            state.jobApplications.firstWhere((a) => a.id == applicationId).jobId);
      }
      if (state.recruiterApplications.isNotEmpty) {
        await fetchRecruiterApplications();
      }
    }
    state = state.copyWith(isLoading: false);
    return result;
  }

  Future<Map<String, dynamic>> withdraw(String applicationId) async {
    state = state.copyWith(isLoading: true);
    final result = await ApplicationService.withdrawApplication(applicationId);
    if (result['success'] == true) {
      state = state.copyWith(
        myApplications:
            state.myApplications.where((a) => a.id != applicationId).toList(),
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
    return result;
  }
}

final applicationProvider =
    StateNotifierProvider<ApplicationNotifier, ApplicationState>(
        (ref) => ApplicationNotifier());
