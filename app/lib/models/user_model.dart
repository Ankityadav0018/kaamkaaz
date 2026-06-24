import 'driver_profile_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final List<String> skills;
  final String village;
  final String companyName;
  final String businessArea;
  final String language;
  final LocationModel location;
  final String profileImage;
  final UserRatingModel rating;
  final int completedJobsCount;
  final int experienceDays;
  final int experienceYears;
  final String kycStatus; // not_submitted | pending | approved | rejected
  final String kycNote;
  final String aadhaarNumber;
  final String aadhaarImage;
  final String aadhaarBackImage;
  final String livePhotoUrl;
  final bool isPhoneVerified;
  final bool isBlocked;
  final String workerType;
  final List<String> verifiedSkills;
  final DriverProfileModel? driverProfile;
  final Map<String, dynamic>? recruiterVerification;
  final List<PortfolioItemModel> portfolio;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.email = '',
    required this.phone,
    required this.role,
    required this.skills,
    required this.village,
    required this.companyName,
    required this.businessArea,
    required this.language,
    required this.location,
    required this.profileImage,
    required this.rating,
    required this.completedJobsCount,
    required this.experienceDays,
    this.experienceYears = 0,
    required this.kycStatus,
    required this.kycNote,
    this.aadhaarNumber = '',
    this.aadhaarImage = '',
    this.aadhaarBackImage = '',
    this.livePhotoUrl = '',
    required this.isPhoneVerified,
    required this.isBlocked,
    this.workerType = 'general',
    this.verifiedSkills = const [],
    this.driverProfile,
    this.recruiterVerification,
    this.portfolio = const [],
    required this.createdAt,
  });

  bool get isKycApproved => kycStatus == 'approved';
  bool get isKycPending => kycStatus == 'pending';
  bool get isKycNotSubmitted => kycStatus == 'not_submitted';
  bool get isKycRejected => kycStatus == 'rejected';

  bool get isWorker => role == 'worker';
  bool get isRecruiter => role == 'recruiter';
  bool get isAdmin => role == 'admin';
  bool get isDriver => role == 'worker' && workerType == 'driver';
  bool get isGeneralWorker => role == 'worker' && workerType == 'general';

  bool get isRecruiterVerified =>
      recruiterVerification != null &&
      recruiterVerification!['status'] == 'verified';
  bool get isRecruiterPending =>
      recruiterVerification != null &&
      recruiterVerification!['status'] == 'pending';
  bool get isRecruiterNotSubmitted =>
      recruiterVerification == null ||
      recruiterVerification!['status'] == 'not_submitted';
  bool get isRecruiterSuspended =>
      recruiterVerification != null &&
      recruiterVerification!['status'] == 'suspended';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: (json['email'] == 'None' || json['email'] == null) ? '' : json['email'],
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'worker',
      skills: List<String>.from(json['skills'] ?? []),
      village: json['village'] ?? '',
      companyName: json['companyName'] ?? '',
      businessArea: json['businessArea'] ?? '',
      language: json['language'] ?? 'hi',
      location: LocationModel.fromJson(json['location'] ?? {}),
      profileImage: json['profileImage'] ?? '',
      rating: UserRatingModel.fromJson(json['rating'] ?? {}),
      completedJobsCount: json['completedJobsCount'] ?? 0,
      experienceDays: json['experienceDays'] ?? 0,
      experienceYears: json['experienceYears'] ?? 0,
      kycStatus: json['kycStatus'] ?? 'not_submitted',
      kycNote: json['kycNote'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      aadhaarImage: json['aadhaarImage'] ?? '',
      aadhaarBackImage: json['aadhaarBackImage'] ?? '',
      livePhotoUrl: json['livePhotoUrl'] ?? '',
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      workerType: json['workerType'] ?? 'general',
      verifiedSkills: List<String>.from(json['verifiedSkills'] ?? []),
      driverProfile: json['driverProfile'] != null
          ? DriverProfileModel.fromJson(json['driverProfile'])
          : null,
      recruiterVerification: json['recruiterVerification'],
      portfolio: (json['portfolio'] as List?)
              ?.map((e) => PortfolioItemModel.fromJson(e))
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'skills': skills,
        'village': village,
        'companyName': companyName,
        'businessArea': businessArea,
        'language': language,
        'location': location.toJson(),
        'profileImage': profileImage,
        'rating': rating.toJson(),
        'completedJobsCount': completedJobsCount,
        'experienceDays': experienceDays,
        'experienceYears': experienceYears,
        'kycStatus': kycStatus,
        'kycNote': kycNote,
        'aadhaarNumber': aadhaarNumber,
        'aadhaarImage': aadhaarImage,
        'aadhaarBackImage': aadhaarBackImage,
        'livePhotoUrl': livePhotoUrl,
        'isPhoneVerified': isPhoneVerified,
        'workerType': workerType,
        'driverProfile': driverProfile?.toJson(),
        'portfolio': portfolio.map((e) => e.toJson()).toList(),
      };
}

class LocationModel {
  final String type;
  final List<double> coordinates;
  final String address;

  LocationModel(
      {required this.type, required this.coordinates, required this.address});

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      type: json['type'] ?? 'Point',
      coordinates: List<double>.from((json['coordinates'] ?? [0.0, 0.0])
          .map((e) => (e as num).toDouble())),
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() =>
      {'type': type, 'coordinates': coordinates, 'address': address};
}

class UserRatingModel {
  final double average;
  final int count;

  UserRatingModel({required this.average, required this.count});

  factory UserRatingModel.fromJson(Map<String, dynamic> json) {
    return UserRatingModel(
      average: (json['average'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'average': average, 'count': count};
}

class PortfolioItemModel {
  final String id;
  final String descriptionHindi;
  final String descriptionEnglish;
  final String mediaUrl;
  final String mediaType; // 'image', 'video', 'text'
  final String publicId;
  final DateTime createdAt;

  PortfolioItemModel({
    required this.id,
    this.descriptionHindi = '',
    this.descriptionEnglish = '',
    this.mediaUrl = '',
    this.mediaType = 'text',
    this.publicId = '',
    required this.createdAt,
  });

  factory PortfolioItemModel.fromJson(Map<String, dynamic> json) {
    return PortfolioItemModel(
      id: json['_id'] ?? json['id'] ?? '',
      descriptionHindi: json['descriptionHindi'] ?? '',
      descriptionEnglish: json['descriptionEnglish'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      mediaType: json['mediaType'] ?? 'text',
      publicId: json['publicId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'descriptionHindi': descriptionHindi,
        'descriptionEnglish': descriptionEnglish,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'publicId': publicId,
        'createdAt': createdAt.toIso8601String(),
      };
}
