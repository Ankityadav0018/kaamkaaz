import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../utils/api_config.dart';

class SecureUploadService {
  static Future<Map<String, dynamic>> uploadImage({
    required String filePath,
    required String uploadType, // e.g., 'kyc', 'profile', 'driver_docs'
  }) async {
    try {
      // 1. Get a secure signed upload token from our backend
      final sigRes =
          await ApiService.get('${ApiConfig.uploadSignature}?type=$uploadType');

      if (sigRes['success'] != true) {
        return {
          'success': false,
          'message': sigRes['message'] ?? 'Failed to get upload authorization'
        };
      }

      final sigData = sigRes['data'];
      final String cloudName = sigData['cloudName'];
      final String apiKey = sigData['apiKey'];
      final String signature = sigData['signature'];
      final int timestamp = sigData['timestamp'];
      final String folder = sigData['folder'];
      final String? publicId = sigData['publicId'];

      // 2. Upload directly to Cloudinary using the signature
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add Cloudinary mandatory fields
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      request.fields['folder'] = folder;
      if (publicId != null) request.fields['public_id'] = publicId;

      // Security: Mandatory transformations can be enforced here too
      request.fields['transformation'] = 'q_auto,f_auto';

      // Attach the file
      final file = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(file);

      // Execute the upload
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'url': responseData['secure_url'],
          'public_id': responseData['public_id'],
        };
      } else {
        return {
          'success': false,
          'message':
              'Cloudinary upload failed: ${responseData['error']?['message'] ?? 'Unknown error'}'
        };
      }
    } on SocketException {
      return {'success': false, 'message': '📶 No internet connection'};
    } on TimeoutException {
      return {
        'success': false,
        'message':
            '⏳ Server is starting up... Please wait a moment and try again.'
      };
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }
}
