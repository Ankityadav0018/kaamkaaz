import '../models/job_model.dart';
import '../utils/api_config.dart';
import 'api_service.dart';

class JobService {
  static Future<List<JobModel>> getNearbyJobs(
      {double? lat,
      double? lng,
      int? radius,
      String? category,
      double? minWage,
      double? maxWage,
      bool? urgentOnly,
      String? keyword,
      String? jobType,
      int page = 1}) async {
    String endpoint = '${ApiConfig.nearbyJobs}?page=$page&limit=30';
    if (lat != null && lng != null) endpoint += '&lat=$lat&lng=$lng';
    if (radius != null) endpoint += '&radius=$radius';
    if (category != null) endpoint += '&category=$category';
    if (minWage != null && minWage > 0) endpoint += '&minWage=$minWage';
    if (maxWage != null && maxWage < 2000) {
      endpoint += '&maxWage=$maxWage';
    } else if (maxWage == 2000) {
      // 2000 is the slider's max limit, which should mean "no maximum"
      endpoint += '&maxWage=999999';
    }
    if (urgentOnly != null) endpoint += '&urgentOnly=$urgentOnly';
    if (keyword != null && keyword.isNotEmpty) {
      endpoint += '&keyword=${Uri.encodeComponent(keyword)}';
    }
    if (jobType != null) endpoint += '&jobType=$jobType';

    final res = await ApiService.get(endpoint);
    if (res['success'] == true && res['data'] != null) {
      return (res['data'] as List).map((j) => JobModel.fromJson(j)).toList();
    }
    return [];
  }

  static Future<List<JobModel>> getMyJobs(
      {String? status, int page = 1}) async {
    String endpoint = '${ApiConfig.myJobs}?page=$page&limit=20';
    if (status != null) endpoint += '&status=$status';
    final res = await ApiService.get(endpoint);
    if (res['success'] == true && res['data'] != null) {
      return (res['data'] as List).map((j) => JobModel.fromJson(j)).toList();
    }
    return [];
  }

  static Future<JobModel?> getJobById(String jobId) async {
    final res = await ApiService.get('${ApiConfig.jobDetail}/$jobId');
    if (res['success'] == true && res['data'] != null) {
      return JobModel.fromJson(res['data']);
    }
    return null;
  }

  static Future<Map<String, dynamic>> postJob(
      Map<String, dynamic> jobData) async {
    List<String> images = [];
    if (jobData.containsKey('images')) {
      images = List<String>.from(jobData['images']);
      jobData.remove(
          'images'); // remove from fields since it will be sent as files
    }

    final res =
        await ApiService.postMultipart(ApiConfig.jobDetail, jobData, images);

    if (res['success'] == true && res['data'] != null) {
      final result = {
        'success': true, 
        'job': JobModel.fromJson(res['data'])
      };
      
      if (res['isUrgentOrder'] == true) {
        result['isUrgentOrder'] = true;
        result['order_id'] = res['order_id'];
        result['amount'] = res['amount'];
        result['currency'] = res['currency'];
        result['razorpay_key_id'] = res['razorpay_key_id'];
      }
      
      return result;
    }
    return {
      'success': false,
      'message': res['message'] ?? 'Failed to post job'
    };
  }

  static Future<Map<String, dynamic>> updateJob(
      String jobId, Map<String, dynamic> jobData) async {
    List<String> images = [];
    if (jobData.containsKey('images')) {
      images = List<String>.from(jobData['images']);
      jobData.remove('images'); // remove from fields since it will be sent as files
    }

    final res =
        await ApiService.putMultipart('${ApiConfig.jobDetail}/$jobId', jobData, images);

    if (res['success'] == true && res['data'] != null) {
      return {'success': true, 'job': JobModel.fromJson(res['data'])};
    }
    return {
      'success': false,
      'message': res['message'] ?? 'Failed to update job'
    };
  }

  static Future<Map<String, dynamic>> updateJobStatus(
      String jobId, String status) async {
    final res = await ApiService.put(
        '${ApiConfig.jobStatus}/$jobId/status', {'status': status});
    return {'success': res['success'] == true, 'message': res['message'] ?? ''};
  }

  static Future<Map<String, dynamic>> deleteJob(String jobId) async {
    final res = await ApiService.delete('${ApiConfig.jobDetail}/$jobId');
    return {'success': res['success'] == true, 'message': res['message'] ?? ''};
  }
}
