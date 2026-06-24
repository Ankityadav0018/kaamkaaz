import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static Future<String?> uploadImageDirectly(String filePath, {String folder = 'kyc_documents'}) async {
    try {
      // 1. Get Signature from our backend
      final sigRes = await ApiService.post('/kyc/upload-url', {'folder': folder});
      if (sigRes['success'] != true) {
        debugPrint('Failed to get upload signature: ${sigRes['message']}');
        return null;
      }

      final data = sigRes['data'];
      final uploadUrl = data['uploadUrl'];

      // 2. Prepare Multipart Request to Cloudinary
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      request.fields['api_key'] = data['apiKey'];
      request.fields['timestamp'] = data['timestamp'].toString();
      request.fields['signature'] = data['signature'];
      request.fields['folder'] = data['folder'];
      request.fields['transformation'] = 'q_auto,f_auto';

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      // 3. Send and parse response
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url']; // The public URL of the uploaded image
      } else {
        debugPrint('Cloudinary Error: ${jsonResponse['error']['message']}');
        return null;
      }
    } catch (e) {
      debugPrint("Cloudinary Upload Error: $e");
      return null;
    }
  }
}
