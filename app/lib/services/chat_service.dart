import 'api_service.dart';
import '../utils/api_config.dart';

class ChatService {
  static Future<List<dynamic>> getInbox() async {
    try {
      final res = await ApiService.get(ApiConfig.chatInbox);
      if (res['success'] == true) {
        return res['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getChatHistory(
      String jobId, String otherUserId) async {
    try {
      final res =
          await ApiService.get('${ApiConfig.chatThread}/$jobId/$otherUserId');
      if (res['success'] == true) {
        return res['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
