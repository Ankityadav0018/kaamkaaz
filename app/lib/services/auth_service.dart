import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../utils/api_config.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';
import 'secure_upload_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
    required String aadhaarNumber,
    List<String>? skills,
    String? village,
    String? companyName,
    String? businessArea,
    String? workerType,
    String? referralCode,
    String language = 'hi',
  }) async {
    final body = {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'role': role,
      'language': language,
      'aadhaarNumber': aadhaarNumber,
      if (skills != null) 'skills': skills,
      if (village != null) 'village': village,
      if (companyName != null) 'companyName': companyName,
      if (businessArea != null) 'businessArea': businessArea,
      if (workerType != null) 'workerType': workerType,
      if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
    };
    final res = await ApiService.post(ApiConfig.register, body, auth: false);
    if (res['success'] == true && res['data'] != null) {
      await ApiService.saveToken(res['data']['token']);
      return {
        'success': true,
        'user': UserModel.fromJson(res['data']['user']),
      };
    }
    return {
      'success': false,
      'message': res['message'] ?? 'Registration failed'
    };
  }

  // identifier can be a 10-digit phone number OR email address
  static Future<Map<String, dynamic>> login(
      String identifier, String password, {bool rememberMe = false}) async {
    final isEmail = identifier.contains('@');
    
    if (isEmail) {
      try {
        final AuthResponse res = await Supabase.instance.client.auth.signInWithPassword(
          email: identifier.trim().toLowerCase(),
          password: password,
        );
        final idToken = res.session?.accessToken;
        if (idToken != null) {
          final verifyRes = await verifyWithSupabase(idToken, '', persist: true);
          if (verifyRes['success'] == true) {
            final user = verifyRes['user'] as UserModel;
            if (user.role == 'admin') {
              // Try auto-login as admin to get the pending token
              final adminRes = await adminLogin(identifier, password);
              if (adminRes['success'] == true) {
                return {'success': true, 'requireAdminOtp': true, 'otpMethod': adminRes['otpMethod']};
              }
            }
          }
          return verifyRes;
        }
        return {'success': false, 'message': 'Failed to retrieve auth token'};
      } on AuthException catch (e) {
        // Fallback: Try admin login if Supabase auth fails
        final adminRes = await adminLogin(identifier, password);
        if (adminRes['success'] == true) {
          return {'success': true, 'requireAdminOtp': true, 'otpMethod': adminRes['otpMethod']};
        }

        String msg = 'Login failed';
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          msg = 'error_invalid_credential';
        }
        return {'success': false, 'message': msg};
      } catch (e) {
        return {'success': false, 'message': ErrorHandler.getMessage(e)};
      }
    } else {
      // Legacy phone login uses backend bcrypt
      final body = {
        'phone': identifier.trim().replaceAll('+91', '').replaceAll(' ', ''),
        'password': password,
        'rememberMe': rememberMe,
      };
      final res = await ApiService.post(ApiConfig.login, body, auth: false);
      if (res['success'] == true && res['data'] != null) {
        final user = UserModel.fromJson(res['data']['user']);
        // Save the regular token first — needed for socket, getMe, notifications etc.
        await ApiService.saveToken(res['data']['token'], persist: true);

        if (user.role == 'admin' && user.email.isNotEmpty) {
          // Admin must go through 2FA even if they logged in via phone.
          // Their email is known from the login response.
          final adminRes = await adminLogin(user.email, password);
          if (adminRes['success'] == true) {
            return {
              'success': true,
              'requireAdminOtp': adminRes['requireAdminOtp'] == true,
              'requireSetup':    adminRes['requireSetup']    == true,
              'otpMethod':       adminRes['otpMethod'],
              'phone':           adminRes['phone'],
            };
          }
          // Admin 2FA failed (wrong email/password combo on admin endpoint),
          // but regular token is still valid — adminSession.js accepts it too.
        }

        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': res['message'] ?? 'Login failed'};
    }
  }

  static Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    final body = {
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    try {
      final res = await ApiService.post(ApiConfig.adminLogin, body, auth: false);
      if (res['success'] == true && res['token'] != null) {
        // Clear any old full admin token so it doesn't interfere with OTP stage
        await ApiService.deleteAdminToken();
        // Temporarily save the pending token so ApiService can use it for verify-otp / setup-phone
        await ApiService.saveToken(res['token'], persist: false); 
        
        return {
          'success': true, 
          'message': res['message'], 
          'requireSetup': res['requireSetup'] == true,
          'requireAdminOtp': res['requireAdminOtp'] == true,
          'phone': res['phone']
        };
      }
      return {'success': false, 'message': res['message'] ?? 'Admin login failed'};
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> adminSetupPhone(String idToken) async {
    try {
      final res = await ApiService.post(ApiConfig.adminSetupPhone, {'idToken': idToken}, auth: true);
      if (res['success'] == true && res['token'] != null) {
        // Save admin token to its own storage key (separate from regular user token)
        await ApiService.saveAdminToken(res['token']);
        if (res['admin'] != null) {
          final userJson = Map<String, dynamic>.from(res['admin']);
          userJson['role'] = 'admin'; // Ensure role is injected
          return {'success': true, 'user': UserModel.fromJson(userJson)};
        }
      }
      return {'success': false, 'message': res['message'] ?? 'Phone setup failed'};
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> adminVerifyOtp(String idToken) async {
    try {
      final res = await ApiService.post(ApiConfig.adminVerifyOtp, {'idToken': idToken}, auth: true);
      if (res['success'] == true && res['token'] != null) {
        // Save admin token to its own storage key (separate from regular user token)
        await ApiService.saveAdminToken(res['token']);
        // Also save it as the regular token so that app restarts can initialize the user correctly
        await ApiService.saveToken(res['token'], persist: true);
        if (res['admin'] != null) {
          final userJson = Map<String, dynamic>.from(res['admin']);
          userJson['role'] = 'admin';
          return {'success': true, 'user': UserModel.fromJson(userJson)};
        }
      }
      return {'success': false, 'message': res['message'] ?? 'Verification failed'};
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> checkPhone(String phone) async {
    return await ApiService.post('/auth/check-phone', {'phone': phone},
        auth: false);
  }

  static Future<bool> checkEmail(String email) async {
    try {
      final res = await ApiService.post(
          ApiConfig.checkEmail, {'email': email},
          auth: false);
      return res['exists'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> requestOTP(String phone) async {
    try {
      final formattedPhone = phone.startsWith('+91') ? phone : '+91${phone.replaceAll(RegExp(r'\D'), '')}';
      await Supabase.instance.client.auth.signInWithOtp(
        phone: formattedPhone,
      );
      return {'success': true, 'otp': 'Sent via SMS'}; // Supabase sends real SMS
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> verifyOTP(
      String phone, String otp) async {
    try {
      final formattedPhone = phone.startsWith('+91') ? phone : '+91${phone.replaceAll(RegExp(r'\D'), '')}';
      final AuthResponse res = await Supabase.instance.client.auth.verifyOTP(
        phone: formattedPhone,
        token: otp,
        type: OtpType.sms,
      );
      
      final idToken = res.session?.accessToken;
      if (idToken != null) {
        return await verifyWithSupabase(idToken, formattedPhone); 
      }
      return {'success': false, 'message': 'Failed to retrieve auth token'};
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> verifyWithSupabase(
      String idToken, String phone, {bool persist = true}) async {
    final res = await ApiService.post(
        ApiConfig.supabaseVerify,
        {
          'idToken': idToken,
          if (phone.isNotEmpty) 'phone': phone,
        },
        auth: false);

    if (res['success'] == true) {
      if (res['token'] != null) {
        await ApiService.saveToken(res['token'], persist: persist);
      }
      if (res['user'] != null) {
        return {'success': true, 'user': UserModel.fromJson(res['user'])};
      }
    }
    return {
      'success': false,
      'message': res['message'] ?? 'Supabase verification failed'
    };
  }

  static Future<UserModel?> getMe() async {
    final res = await ApiService.get(ApiConfig.me);
    if (res['success'] == true && res['data'] != null) {
      return UserModel.fromJson(res['data']);
    }
    return null;
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> fields) async {
    final res = await ApiService.put(ApiConfig.updateProfile, fields);
    if (res['success'] == true && res['data'] != null) {
      return {'success': true, 'user': UserModel.fromJson(res['data'])};
    }
    return {'success': false, 'message': res['message'] ?? 'Update failed'};
  }

  static Future<Map<String, dynamic>> updateLocation(
      double lat, double lng, String address) async {
    final res = await ApiService.put(ApiConfig.updateLocation, {
      'coordinates': [lng, lat],
      'address': address,
    });
    if (res['success'] == true && res['data'] != null) {
      return {'success': true, 'user': UserModel.fromJson(res['data'])};
    }
    return {'success': false, 'message': res['message']};
  }

  static Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    await ApiService.deleteToken();
    await ApiService.deleteAdminToken(); // always clear admin token too
  }

  static Future<Map<String, dynamic>> updateKyc({
    required String aadhaarFront,
    required String aadhaarBack,
    required String livePhoto,
    String? licenceFront,
    String? licenceBack,
    String? aadhaarNumber,
    int? experienceYears,
  }) async {
    try {
      final Map<String, dynamic> body = {
        if (aadhaarNumber != null) 'aadhaarNumber': aadhaarNumber,
        if (experienceYears != null) 'experienceYears': experienceYears,
      };

      // 1. Securely upload images to Cloudinary via backend-signed signatures

      final frontRes = await SecureUploadService.uploadImage(
          filePath: aadhaarFront, uploadType: 'kyc');
      if (!frontRes['success']) {
        throw Exception('Aadhaar Front: ${frontRes['message']}');
      }
      body['aadhaarImage'] = frontRes['url'];
      body['aadhaarImagePublicId'] = frontRes['public_id'];

      final backRes = await SecureUploadService.uploadImage(
          filePath: aadhaarBack, uploadType: 'kyc');
      if (!backRes['success']) {
        throw Exception('Aadhaar Back: ${backRes['message']}');
      }
      body['aadhaarBackImage'] = backRes['url'];
      body['aadhaarBackImagePublicId'] = backRes['public_id'];

      final liveRes = await SecureUploadService.uploadImage(
          filePath: livePhoto, uploadType: 'kyc');
      if (!liveRes['success']) {
        throw Exception('Live Photo: ${liveRes['message']}');
      }
      body['livePhotoUrl'] = liveRes['url'];
      body['livePhotoPublicId'] = liveRes['public_id'];

      if (licenceFront != null) {
        final lfRes = await SecureUploadService.uploadImage(
            filePath: licenceFront, uploadType: 'driver_docs');
        if (!lfRes['success']) {
          throw Exception('Licence Front: ${lfRes['message']}');
        }
        body['licenceFrontUrl'] = lfRes['url'];
        body['licenceFrontPublicId'] = lfRes['public_id'];
      }

      if (licenceBack != null) {
        final lbRes = await SecureUploadService.uploadImage(
            filePath: licenceBack, uploadType: 'driver_docs');
        if (!lbRes['success']) {
          throw Exception('Licence Back: ${lbRes['message']}');
        }
        body['licenceBackUrl'] = lbRes['url'];
        body['licenceBackPublicId'] = lbRes['public_id'];
      }

      // 2. Submit final URLs and Public IDs to backend

      body['kycStatus'] = 'submitted';
      final res = await ApiService.put(ApiConfig.updateKyc, body);

      if (res['success'] == true && res['data'] != null) {
        return {'success': true, 'user': UserModel.fromJson(res['data'])};
      }
      return res;
      } catch (e) {
        return {
          'success': false,
          'message': ErrorHandler.getMessage(e)
        };
      }
  }

  static Future<Map<String, dynamic>> addPortfolioItem({
    required String description,
    String? mediaPath,
    required String mediaType, // 'image', 'video', 'text'
  }) async {
    try {
      String mediaUrl = '';
      String publicId = '';

      if (mediaPath != null && mediaPath.isNotEmpty) {
        final uploadRes = await SecureUploadService.uploadImage(
          filePath: mediaPath,
          uploadType: 'portfolio',
        );
        if (!uploadRes['success']) {
          throw Exception(uploadRes['message'] ?? 'Upload failed');
        }
        mediaUrl = uploadRes['url'];
        publicId = uploadRes['public_id'];
      }

      final body = {
        'description': description,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'publicId': publicId,
      };

      final res = await ApiService.post('/auth/portfolio', body);
      if (res['success'] == true && res['data'] != null) {
        return {
          'success': true,
          'portfolio': (res['data'] as List)
              .map((e) => PortfolioItemModel.fromJson(e))
              .toList(),
        };
      }
      return {'success': false, 'message': res['message'] ?? 'Failed to add portfolio'};
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getMessage(e)};
    }
  }

  static Future<Map<String, dynamic>> deletePortfolioItem(String itemId) async {
    try {
      final res = await ApiService.delete('/auth/portfolio/$itemId');
      if (res['success'] == true && res['data'] != null) {
        return {
          'success': true,
          'portfolio': (res['data'] as List)
              .map((e) => PortfolioItemModel.fromJson(e))
              .toList(),
        };
      }
      return {'success': false, 'message': res['message'] ?? 'Failed to delete portfolio'};
    } catch (e) {
      return {'success': false, 'message': ErrorHandler.getMessage(e)};
    }
  }
}
