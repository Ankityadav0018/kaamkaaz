import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';
import '../utils/error_handler.dart';
import 'logger_service.dart';

class ApiService {
  // Use EncryptedSharedPreferences on Android — avoids Keystore timeout issues
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      
    ),
  );
  static const _tokenKey = 'kaamkaaz_auth_token';
  static const _adminTokenKey = 'kaamkaaz_admin_token';
  static Function? onUnauthorized;
  static Function? onAdminSessionExpired; // separate handler for admin 401s

  // In-memory token for session-only logins (rememberMe = false)
  static String? _memoryToken;

  // Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Token management
  /// [persist] = true → store in EncryptedSharedPreferences (survives restarts).
  /// [persist] = false → store in memory only (cleared on restart).
  static Future<void> saveToken(String token, {bool persist = true}) async {
    if (persist) {
      _memoryToken = null; // clear memory copy
      await _storage.write(key: _tokenKey, value: token);
    } else {
      _memoryToken = token; // session-only
      await _storage.delete(key: _tokenKey); // ensure no stale persisted token
    }
  }

  static Future<String?> getToken() async {
    // Check memory first (session-only tokens live here)
    if (_memoryToken != null) return _memoryToken;
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      LoggerService.e('Secure storage read error: $e');
      return null;
    }
  }

  static Future<void> deleteToken() async {
    _memoryToken = null;
    await _storage.delete(key: _tokenKey);
  }

  // ── Admin token (separate key, never overwritten by regular login) ──────────
  static Future<void> saveAdminToken(String token) async {
    await _storage.write(key: _adminTokenKey, value: token);
  }

  static Future<String?> getAdminToken() async {
    try {
      return await _storage.read(key: _adminTokenKey);
    } catch (e) {
      LoggerService.e('Secure storage admin token read error: $e');
      return null;
    }
  }

  static Future<void> deleteAdminToken() async {
    await _storage.delete(key: _adminTokenKey);
  }

  static Future<void> clearAllData() async {
    _memoryToken = null;
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Build headers — admin routes automatically use the admin token when available
  static Future<Map<String, String>> _headers({bool auth = true, bool adminAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      String? token;
      if (adminAuth) {
        // Prefer admin token; fall back to regular token
        token = await getAdminToken() ?? await getToken();
        headers['x-admin-intent'] = 'App Navigation';
      } else {
        token = await getToken();
      }
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Centralized request handler with retry logic
  static Future<Map<String, dynamic>> _requestWithRetry(
    Future<http.Response> Function() requestFn, {
    int retries = 0,
    bool isAdminRoute = false,
  }) async {
    try {
      final response = await requestFn().timeout(const Duration(seconds: 60));

      if ((response.statusCode == 502 || response.statusCode == 503) &&
          retries < maxRetries) {
        LoggerService.w(
            '⚠️ Server busy (${response.statusCode}). Retrying ${retries + 1}/$maxRetries...');
        await Future.delayed(retryDelay * (retries + 1));
        return _requestWithRetry(requestFn, retries: retries + 1, isAdminRoute: isAdminRoute);
      }

      return _handleResponse(response, isAdminRoute: isAdminRoute);
    } on SocketException {
      if (retries < maxRetries) {
        LoggerService.w(
            '📶 Connection lost. Retrying ${retries + 1}/$maxRetries...');
        await Future.delayed(retryDelay * (retries + 1));
        return _requestWithRetry(requestFn, retries: retries + 1, isAdminRoute: isAdminRoute);
      }
      throw ErrorHandler.getMessage('No internet connection.');
    } on TimeoutException {
      if (retries < maxRetries) {
        LoggerService.w(
            '⏳ Request timed out. Retrying ${retries + 1}/$maxRetries...');
        await Future.delayed(retryDelay * (retries + 1));
        return _requestWithRetry(requestFn, retries: retries + 1, isAdminRoute: isAdminRoute);
      }
      throw ErrorHandler.getMessage('TimeoutException: Server is taking too long');
    } catch (e) {
      if (e is String) rethrow;
      throw ErrorHandler.getMessage(e);
    }
  }

  // GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final isAdminRoute = endpoint.startsWith('/admin/');
    return _requestWithRetry(() async => http.get(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: await _headers(adminAuth: isAdminRoute),
        ), isAdminRoute: isAdminRoute);
  }

  // POST
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body,
      {bool auth = true}) async {
    final isAdminRoute = endpoint.startsWith('/admin/');
    return _requestWithRetry(() async => http.post(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: await _headers(auth: auth, adminAuth: isAdminRoute),
          body: jsonEncode(body),
        ), isAdminRoute: isAdminRoute);
  }

  // PUT
  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final isAdminRoute = endpoint.startsWith('/admin/');
    return _requestWithRetry(() async => http.put(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: await _headers(adminAuth: isAdminRoute),
          body: jsonEncode(body),
        ), isAdminRoute: isAdminRoute);
  }

  // PATCH
  static Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> body) async {
    final isAdminRoute = endpoint.startsWith('/admin/');
    return _requestWithRetry(() async => http.patch(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: await _headers(adminAuth: isAdminRoute),
          body: jsonEncode(body),
        ), isAdminRoute: isAdminRoute);
  }

  // DELETE
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final isAdminRoute = endpoint.startsWith('/admin/');
    return _requestWithRetry(() async => http.delete(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: await _headers(adminAuth: isAdminRoute),
        ), isAdminRoute: isAdminRoute);
  }

  // MULTIPART
  static Future<Map<String, dynamic>> postMultipart(
      String endpoint, Map<String, dynamic> fields, List<String> filePaths,
      {String fileField = 'images'}) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      fields.forEach((key, value) {
        if (value is String) {
          request.fields[key] = value;
        } else if (value != null) {
          request.fields[key] = jsonEncode(value);
        }
      });

      for (String path in filePaths) {
        request.files.add(await http.MultipartFile.fromPath(fileField, path));
      }

      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 90)); // Longer for files
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw '📶 No internet connection';
    } on TimeoutException {
      throw '⏳ Upload timed out. Please try again with better connection.';
    } catch (e) {
      throw 'Upload error: $e';
    }
  }

  static Future<Map<String, dynamic>> putMultipart(
      String endpoint, Map<String, dynamic> fields, List<String> filePaths,
      {String fileField = 'images'}) async {
    try {
      final token = await getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final request = http.MultipartRequest('PUT', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      fields.forEach((key, value) {
        if (value is String) {
          request.fields[key] = value;
        } else if (value != null) {
          request.fields[key] = jsonEncode(value);
        }
      });

      for (String path in filePaths) {
        request.files.add(await http.MultipartFile.fromPath(fileField, path));
      }

      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 90)); // Longer for files
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw ErrorHandler.getMessage('SocketException: No internet connection');
    } on TimeoutException {
      throw ErrorHandler.getMessage('TimeoutException: Upload timed out.');
    } catch (e) {
      throw ErrorHandler.getMessage('Upload error: $e');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response, {bool isAdminRoute = false}) {
    LoggerService.i(
        '🌐 API Response: ${response.request?.method} ${response.request?.url} -> ${response.statusCode}');

    if (response.statusCode == 401) {
      final isLoginAttempt = response.request != null &&
          (response.request!.url.path.contains('/login') ||
           response.request!.url.path.contains('/supabase-verify') ||
           response.request!.url.path.contains('/register'));

      if (!isLoginAttempt) {
        if (isAdminRoute) {
          // Admin session expired — don't log the whole user out;
          // let the admin screen show a re-authenticate dialog instead.
          if (onAdminSessionExpired != null) onAdminSessionExpired!();
        } else {
          if (onUnauthorized != null) onUnauthorized!();
        }
        throw 'error_generic';
      }
      // If it is a login attempt, let it fall through to parse the specific error message from the backend
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw ErrorHandler.getMessage(body['message'] ?? 'Server error (${response.statusCode})');
      }
      return body;
    } catch (e) {
      if (e is String) rethrow;
      throw ErrorHandler.getMessage('Invalid server response (${response.statusCode})');
    }
  }
}
