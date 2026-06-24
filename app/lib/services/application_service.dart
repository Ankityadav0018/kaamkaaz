import '../models/application_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import '../utils/api_config.dart';

class ApplicationService {
  static Future<Map<String, dynamic>> applyForJob(String jobId,
      {String? message, double? preferredWage}) async {
    final body = <String, dynamic>{'jobId': jobId};
    if (message != null) body['message'] = message;
    if (preferredWage != null) body['preferredWage'] = preferredWage;
    final res = await ApiService.post(ApiConfig.applications, body);
    return {'success': res['success'] == true, 'message': res['message'] ?? ''};
  }

  static Future<List<ApplicationModel>> getMyApplications(
      {String? status, int page = 1}) async {
    String endpoint = '/applications/my-applications?page=$page&limit=1000';
    if (status != null) endpoint += '&status=$status';
    final res = await ApiService.get(endpoint);
    if (res['success'] == true && res['data'] != null) {
      return (res['data'] as List)
          .map((a) => ApplicationModel.fromJson(a))
          .toList();
    }
    return [];
  }

  static Future<List<ApplicationModel>> getRecruiterApplications(
      {String? status, int page = 1}) async {
    String endpoint = '${ApiConfig.recruiterAllApplications}?page=$page&limit=1000';
    if (status != null) endpoint += '&status=$status';
    final res = await ApiService.get(endpoint);
    if (res['success'] == true && res['data'] != null) {
      return (res['data'] as List)
          .map((a) => ApplicationModel.fromJson(a))
          .toList();
    }
    return [];
  }

  static Future<List<ApplicationModel>> getJobApplications(String jobId) async {
    final res = await ApiService.get('${ApiConfig.jobApplications}/$jobId');
    if (res['success'] == true && res['data'] != null) {
      return (res['data'] as List)
          .map((a) => ApplicationModel.fromJson(a))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> acceptApplication(
      String applicationId) async {
    final res = await ApiService.put(
        '${ApiConfig.acceptApplication}/$applicationId/accept', {});
    if (res['success'] == true && res['data'] != null) {
      final workerData = res['data']['worker'];
      return {
        'success': true,
        'message': res['message'],
        'worker': workerData != null ? UserModel.fromJson(workerData) : null,
      };
    }
    return {'success': false, 'message': res['message'] ?? 'Failed'};
  }

  static Future<Map<String, dynamic>> rejectApplication(
      String applicationId) async {
    final res = await ApiService.put(
        '${ApiConfig.rejectApplication}/$applicationId/reject', {});
    return {'success': res['success'] == true, 'message': res['message'] ?? ''};
  }

  static Future<Map<String, dynamic>> withdrawApplication(
      String applicationId) async {
    final res =
        await ApiService.delete('${ApiConfig.applications}/$applicationId');
    return {'success': res['success'] == true, 'message': res['message'] ?? ''};
  }

  static Future<Map<String, dynamic>?> getWorkerFullProfile(
      String applicationId) async {
    final res = await ApiService.get(
        '${ApiConfig.workerProfileFromApp}/$applicationId/worker-profile');
    if (res['success'] == true && res['data'] != null) {
      return {
        'worker': UserModel.fromJson(res['data']),
        'jobId': res['data']['jobId'] ?? '',
      };
    }
    return null;
  }
}
