import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker_model.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class AdminKycState {
  final List<WorkerModel> users;
  final bool isLoading;
  final String? error;

  AdminKycState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  AdminKycState copyWith({
    List<WorkerModel>? users,
    bool? isLoading,
    String? error,
  }) {
    return AdminKycState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminKycNotifier extends StateNotifier<AdminKycState> {
  AdminKycNotifier() : super(AdminKycState());

  Future<void> fetchKycQueue() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await ApiService.get(ApiConfig.adminKycPending);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] as List? ?? [];
        final users = data
            .map((u) => WorkerModel.fromJson(u as Map<String, dynamic>))
            .toList();
        state = state.copyWith(users: users, isLoading: false);
      } else {
        throw response['message'] ?? 'Failed to load KYC queue';
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> reviewKyc(String userId, String status, {String? note}) async {
    try {
      final res = await ApiService.put('${ApiConfig.adminKycReview}/$userId', {
        'status': status,
        'note': note,
      });
      if (res['success'] == true) {
        await fetchKycQueue();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final adminKycProvider =
    StateNotifierProvider<AdminKycNotifier, AdminKycState>((ref) {
  return AdminKycNotifier()..fetchKycQueue();
});
