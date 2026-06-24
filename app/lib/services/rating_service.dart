import 'api_service.dart';
import '../utils/api_config.dart';
import '../models/rating_model.dart';

class RatingService {
  static Future<Map<String, dynamic>> submitRating({
    required String jobId,
    required int score,
    String? comment,
  }) async {
    return await ApiService.post(ApiConfig.ratings, {
      'jobId': jobId,
      'score': score,
      'comment': comment ?? '',
    });
  }

  static Future<List<RatingModel>> getUserRatings(String userId) async {
    final res = await ApiService.get('${ApiConfig.userRatings}/$userId');
    if (res['success'] == true && res['data'] != null) {
      return (res['data'] as List).map((r) => RatingModel.fromJson(r)).toList();
    }
    return [];
  }
}
