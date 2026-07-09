import 'package:kaamkaaz/utils/api_config.dart';
import 'package:kaamkaaz/services/api_service.dart';

class CreditsService {
  /// Get the recruiter's current job posting credit balance and stats.
  static Future<Map<String, dynamic>> getCredits() async {
    final res = await ApiService.get('/credits');
    return res;
  }

  /// Get the recruiter's credit purchase and usage history.
  static Future<Map<String, dynamic>> getCreditHistory(int page, {int limit = 20}) async {
    final res = await ApiService.get('/credits/history?page=$page&limit=$limit');
    return res;
  }

  /// Get available credit packs (Starter / Standard / Pro).
  static Future<Map<String, dynamic>> getAvailablePacks() async {
    final res = await ApiService.get('/credits/packs');
    return res;
  }

  /// Initiate a credit pack purchase via Razorpay.
  /// [packId] must be one of the IDs returned by [getAvailablePacks].
  static Future<Map<String, dynamic>> initiatePurchase(String packId) async {
    final res = await ApiService.post('/credits/purchase', {
      'packId': packId,
    });
    return res;
  }

  /// Verify a completed Razorpay payment for a credit pack purchase.
  static Future<Map<String, dynamic>> verifyPurchase(
      String orderId, String paymentId, String signature) async {
    final res = await ApiService.post('/credits/verify-purchase', {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    });
    return res;
  }
}

// Backward compatibility alias (can be removed after full migration)

