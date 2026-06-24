import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';
import '../utils/api_config.dart';

class ShareService {
  static Future<void> shareJobOnWhatsApp(String jobId) async {
    try {
      final res =
          await ApiService.get('${ApiConfig.jobShareText}/$jobId/share-text');
      if (res['success'] == true) {
        final String text = res['text'];
        final String whatsappUrl = res['whatsappUrl'];

        final Uri uri = Uri.parse(whatsappUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to native share
          await SharePlus.instance.share(ShareParams(text: text));
        }
      }
    } catch (e) {
      return;
    }
  }

  static Future<void> shareReferralOnWhatsApp(String shareText) async {
    try {
      final String encodedText = Uri.encodeComponent(shareText);
      final Uri uri = Uri.parse('whatsapp://send?text=$encodedText');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to web link or native share
        final Uri webUri = Uri.parse('https://wa.me/?text=$encodedText');
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          await SharePlus.instance.share(ShareParams(text: shareText));
        }
      }
    } catch (e) {
      await SharePlus.instance.share(ShareParams(text: shareText));
    }
  }
}
