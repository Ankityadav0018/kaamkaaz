import 'package:kaamkaaz/utils/api_config.dart';
import 'package:kaamkaaz/services/api_service.dart';

class WalletService {
  static Future<Map<String, dynamic>> getWallet() async {
    final res = await ApiService.get('/wallet');
    return res;
  }

  static Future<Map<String, dynamic>> getTransactionHistory(int page, {int limit = 20}) async {
    final res = await ApiService.get('/wallet/history?page=$page&limit=$limit');
    return res;
  }

  static Future<Map<String, dynamic>> initiateTopup(int amountPaise) async {
    final res = await ApiService.post('/wallet/topup', {
      'amount': amountPaise
    });
    return res;
  }

  static Future<Map<String, dynamic>> verifyTopup(String orderId, String paymentId, String signature) async {
    final res = await ApiService.post('/wallet/verify-topup', {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature
    });
    return res;
  }
}
