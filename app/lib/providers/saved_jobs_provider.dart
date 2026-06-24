import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';
import '../services/cache_service.dart';

final savedJobsProvider = StateNotifierProvider<SavedJobsNotifier, List<String>>((ref) {
  return SavedJobsNotifier();
});

class SavedJobsNotifier extends StateNotifier<List<String>> {
  SavedJobsNotifier() : super([]) {
    _loadSavedJobs();
  }

  static const _key = 'saved_job_ids';

  Future<void> _loadSavedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_key) ?? [];
    state = savedIds;
  }

  Future<void> toggleSave(JobModel job) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = List<String>.from(state);

    if (currentList.contains(job.id)) {
      currentList.remove(job.id);
      await CacheService.uncacheJob(job.id);
    } else {
      currentList.add(job.id);
      await CacheService.cacheJob(job);
    }

    await prefs.setStringList(_key, currentList);
    state = currentList;
  }

  bool isSaved(String jobId) {
    return state.contains(jobId);
  }
}
