import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  // 1. Listen to connectivity_plus changes
  yield* connectivity.onConnectivityChanged.asyncMap((results) async {
    // connectivity_plus only tells us if wifi/mobile is on, not if internet works
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) return false;

    // 2. Deep ping check for actual internet
    return await _checkActualInternet();
  });
});

Future<bool> _checkActualInternet() async {
  try {
    final res = await ApiService.get(ApiConfig.healthCheck);
    return res['success'] == true;
  } catch (_) {
    return false;
  }
}

// Simple state provider for UI parts that prefer sync access
final isOnlineProvider = StateProvider<bool>((ref) {
  final stream = ref.watch(connectivityProvider);
  return stream.maybeWhen(
    data: (online) => online,
    orElse: () => true, // Assume online by default
  );
});

// Added to ApiConfig earlier but explicitly here for health
extension ApiConfigHealth on ApiConfig {
  static const String healthCheck = '/health';
}
