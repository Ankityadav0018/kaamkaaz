import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rating_service.dart';
import '../models/rating_model.dart';

class RatingNotifier extends StateNotifier<AsyncValue<void>> {
  RatingNotifier() : super(const AsyncValue.data(null));

  Future<Map<String, dynamic>> submitRating({
    required String jobId,
    required int score,
    String? comment,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await RatingService.submitRating(
        jobId: jobId,
        score: score,
        comment: comment,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return {'success': false, 'message': e.toString()};
    }
  }
}

final ratingProvider =
    StateNotifierProvider<RatingNotifier, AsyncValue<void>>((ref) {
  return RatingNotifier();
});

final userRatingsProvider =
    FutureProvider.family<List<RatingModel>, String>((ref, userId) async {
  return await RatingService.getUserRatings(userId);
});
