import 'user_model.dart';
import 'job_model.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final JobModel? job;
  final String workerId;
  final UserModel? worker;
  final String message;
  final double? preferredWage;
  final String status;
  final bool contactRevealed;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final Map<String, dynamic>? workerRating;
  final Map<String, dynamic>? recruiterRating;

  ApplicationModel({
    required this.id,
    required this.jobId,
    this.job,
    required this.workerId,
    this.worker,
    required this.message,
    this.preferredWage,
    required this.status,
    required this.contactRevealed,
    this.respondedAt,
    required this.createdAt,
    this.workerRating,
    this.recruiterRating,
  });

  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'applied';
  bool get isCompleted => status == 'completed';

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    final jobData = json['jobId'];
    final workerData = json['workerId'];
    return ApplicationModel(
      id: json['_id'] ?? '',
      jobId: jobData is String ? jobData : (jobData?['_id'] ?? ''),
      job: jobData is Map<String, dynamic> ? JobModel.fromJson(jobData) : null,
      workerId: workerData is String ? workerData : (workerData?['_id'] ?? ''),
      worker: workerData is Map<String, dynamic>
          ? UserModel.fromJson(workerData)
          : null,
      message: json['message'] ?? '',
      preferredWage: json['preferredWage'] != null
          ? (json['preferredWage'] as num).toDouble()
          : null,
      status: json['status'] ?? 'applied',
      contactRevealed: json['contactRevealed'] ?? false,
      respondedAt: json['respondedAt'] != null
          ? DateTime.tryParse(json['respondedAt'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      workerRating: json['workerRating'],
      recruiterRating: json['recruiterRating'],
    );
  }
}
