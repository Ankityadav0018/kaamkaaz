import 'user_model.dart';

class JobModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> requiredSkills;
  final double wage;
  final String wageType;
  final int maxWorkers;
  final LocationModel location;
  final List<String> images;
  final DateTime dateTime;
  final int durationValue;
  final String durationUnit;
  final UserModel? recruiter;
  final String recruiterId;
  final UserModel? assignedWorker;
  final String? assignedWorkerId;
  final String status;
  final int applicantCount;
  final bool isUrgent;
  final double distance;
  final bool isApplied;
  final String jobType;
  final Map<String, dynamic>? driverRequirements;
  final bool hasDispute;
  final DateTime? disputeRaisedAt;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.requiredSkills,
    required this.wage,
    required this.wageType,
    required this.maxWorkers,
    required this.location,
    this.images = const [],
    required this.dateTime,
    required this.durationValue,
    required this.durationUnit,
    this.recruiter,
    required this.recruiterId,
    this.assignedWorker,
    this.assignedWorkerId,
    required this.status,
    required this.applicantCount,
    required this.isUrgent,
    this.distance = 0.0,
    this.isApplied = false,
    this.jobType = 'general',
    this.driverRequirements,
    this.hasDispute = false,
    this.disputeRaisedAt,
    required this.createdAt,
  });

  String get formattedWage {
    final unit = wageType == 'hourly'
        ? 'hr'
        : wageType == 'weekly'
            ? 'wk'
            : wageType == 'fixed'
                ? ''
                : 'day';
    return unit.isEmpty ? '₹${wage.toInt()}' : '₹${wage.toInt()}/$unit';
  }

  String get formattedDistance => '${distance.toStringAsFixed(1)} km';

  String get durationText => '$durationValue $durationUnit';

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final recruiterData = json['recruiterId'];
    return JobModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'other',
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      wage: (json['wage'] ?? 0).toDouble(),
      wageType: json['wageType'] ?? 'daily',
      maxWorkers: json['maxWorkers'] ?? 1,
      location: LocationModel.fromJson(json['location'] ?? {}),
      images: List<String>.from(json['images'] ?? []),
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
      durationValue: json['durationValue'] ?? 1,
      durationUnit: json['durationUnit'] ?? 'days',
      recruiterId: recruiterData is String
          ? recruiterData
          : (recruiterData?['_id'] ?? ''),
      recruiter: recruiterData is Map<String, dynamic>
          ? UserModel.fromJson(recruiterData)
          : null,
      assignedWorkerId: json['assignedWorkerId'] is String 
          ? json['assignedWorkerId'] 
          : (json['assignedWorkerId'] is Map ? json['assignedWorkerId']['_id'] : null),
      assignedWorker: json['assignedWorkerId'] is Map<String, dynamic>
          ? UserModel.fromJson(json['assignedWorkerId'])
          : null,
      status: json['status'] ?? 'open',
      applicantCount: json['applicantCount'] ?? 0,
      isUrgent: json['isUrgent'] ?? false,
      distance:
          json['distance'] != null ? (json['distance'] as num).toDouble() : 0.0,
      isApplied: json['isApplied'] ?? false,
      jobType: json['jobType'] ?? 'general',
      driverRequirements: json['driverRequirements'],
      hasDispute: json['hasDispute'] ?? false,
      disputeRaisedAt: json['disputeRaisedAt'] != null
          ? DateTime.tryParse(json['disputeRaisedAt'])
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'description': description,
        'category': category,
        'requiredSkills': requiredSkills,
        'wage': wage,
        'wageType': wageType,
        'maxWorkers': maxWorkers,
        'location': location.toJson(),
        'images': images,
        'dateTime': dateTime.toIso8601String(),
        'durationValue': durationValue,
        'durationUnit': durationUnit,
        'recruiterId': recruiterId,
        'recruiter': recruiter?.toJson(),
        'assignedWorkerId': assignedWorkerId,
        'assignedWorker': assignedWorker?.toJson(),
        'status': status,
        'applicantCount': applicantCount,
        'isUrgent': isUrgent,
        'distance': distance,
        'isApplied': isApplied,
        'jobType': jobType,
        'driverRequirements': driverRequirements,
        'hasDispute': hasDispute,
        'disputeRaisedAt': disputeRaisedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
