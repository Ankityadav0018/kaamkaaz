class DriverProfileModel {
  final List<String> vehicleTypes;
  final int experienceYears;
  final List<String> languages;
  final bool willingToOutstation;
  final bool hasOwnVehicle;
  final String ownVehicleType;
  final String ownVehicleRegNumber;
  final String licenceFrontUrl;
  final String licenceBackUrl;
  final String aadhaarUrl;
  final String rcBookUrl;
  final String policeVerificationUrl;
  final String passportPhotoUrl;
  final String kycStatus; // not_submitted | pending | verified | rejected
  final String kycRejectionReason;
  final DateTime? kycSubmittedAt;
  final DateTime? kycVerifiedAt;

  const DriverProfileModel({
    this.vehicleTypes = const [],
    this.experienceYears = 0,
    this.languages = const [],
    this.willingToOutstation = false,
    this.hasOwnVehicle = false,
    this.ownVehicleType = '',
    this.ownVehicleRegNumber = '',
    this.licenceFrontUrl = '',
    this.licenceBackUrl = '',
    this.aadhaarUrl = '',
    this.rcBookUrl = '',
    this.policeVerificationUrl = '',
    this.passportPhotoUrl = '',
    this.kycStatus = 'not_submitted',
    this.kycRejectionReason = '',
    this.kycSubmittedAt,
    this.kycVerifiedAt,
  });

  bool get isVerified => kycStatus == 'verified';
  bool get isPending => kycStatus == 'pending';
  bool get isNotSubmitted => kycStatus == 'not_submitted';
  bool get isRejected => kycStatus == 'rejected';

  factory DriverProfileModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DriverProfileModel();
    return DriverProfileModel(
      vehicleTypes: List<String>.from(json['vehicleTypes'] ?? []),
      experienceYears: json['experienceYears'] ?? 0,
      languages: List<String>.from(json['languages'] ?? []),
      willingToOutstation: json['willingToOutstation'] ?? false,
      hasOwnVehicle: json['hasOwnVehicle'] ?? false,
      ownVehicleType: json['ownVehicleType'] ?? '',
      ownVehicleRegNumber: json['ownVehicleRegNumber'] ?? '',
      licenceFrontUrl: json['licenceFrontUrl'] ?? '',
      licenceBackUrl: json['licenceBackUrl'] ?? '',
      aadhaarUrl: json['aadhaarUrl'] ?? '',
      rcBookUrl: json['rcBookUrl'] ?? '',
      policeVerificationUrl: json['policeVerificationUrl'] ?? '',
      passportPhotoUrl: json['passportPhotoUrl'] ?? '',
      kycStatus: json['kycStatus'] ?? 'not_submitted',
      kycRejectionReason: json['kycRejectionReason'] ?? '',
      kycSubmittedAt: json['kycSubmittedAt'] != null
          ? DateTime.tryParse(json['kycSubmittedAt'])
          : null,
      kycVerifiedAt: json['kycVerifiedAt'] != null
          ? DateTime.tryParse(json['kycVerifiedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicleTypes': vehicleTypes,
        'experienceYears': experienceYears,
        'languages': languages,
        'willingToOutstation': willingToOutstation,
        'hasOwnVehicle': hasOwnVehicle,
        'ownVehicleType': ownVehicleType,
        'ownVehicleRegNumber': ownVehicleRegNumber,
      };

  static const List<String> kVehicleTypes = [
    'Car / Sedan',
    'SUV / MUV',
    'Mini Bus / Tempo Traveller',
    'Bus',
    'Truck / Heavy Vehicle',
    'Motorcycle / Bike',
    'Tractor',
    'JCB / Excavator',
  ];

  static const List<String> kVehicleEmojis = [
    '🚗',
    '🚙',
    '🚐',
    '🚌',
    '🚛',
    '🏍',
    '🚜',
    '🚧',
  ];

  static const List<String> kLanguages = [
    'Hindi',
    'Punjabi',
    'English',
    'Bengali',
    'Tamil',
    'Telugu',
    'Other',
  ];
}
