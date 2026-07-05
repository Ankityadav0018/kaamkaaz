import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

// Analytics stats provider - used only in Admin Analytics screen
final analyticsStatsProvider =
    StreamProvider.autoDispose.family<Map<String, dynamic>, int>((ref, days) async* {
  bool isDisposed = false;
  ref.onDispose(() => isDisposed = true);

  // Poll every 10 seconds for real-time updates
  while (!isDisposed) {
    try {
      final res = await ApiService.get('${ApiConfig.adminAnalytics}?days=$days');
      if (res['success'] == true) {
        yield res['data'];
      }
    } catch (e) {
      // Yield previous data or ignore to avoid flickering on transient errors
    }
    if (isDisposed) break;
    await Future.delayed(const Duration(seconds: 10));
  }
});

// Referral stats provider - used only in Referral screen
final referralStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService.get(ApiConfig.myReferral);
  if (res['success'] == true) {
    return res['data'];
  }
  throw res['message'] ?? 'Failed to fetch referral info';
});

// Past workers provider - used only in Recruiter's Past Workers screen
final pastWorkersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService.get(ApiConfig.pastWorkers);
  if (res['success'] == true) {
    return res['data'] ?? [];
  }
  throw res['message'] ?? 'Failed to fetch past workers';
});

// Worker stats provider - used in Worker's My Jobs screen
final workerStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService.get(ApiConfig.workerStats);
  if (res['success'] == true) {
    return res['data'];
  }
  throw res['message'] ?? 'Failed to fetch worker stats';
});

// Recruiter stats provider - used in Recruiter home
final recruiterStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService.get(ApiConfig.recruiterStats);
  if (res['success'] == true) {
    return res['data'];
  }
  throw res['message'] ?? 'Failed to fetch recruiter stats';
});
