class WorkerModel {
  final String id;
  final String? name;
  final String? phone;
  final String? selfieUrl;
  final String? aadhaarFrontUrl;
  final String? aadhaarBackUrl;
  final String? aadhaarNumber;
  final String kycStatus;
  final DateTime? kycSubmittedAt;

  WorkerModel({
    required this.id,
    this.name,
    this.phone,
    this.selfieUrl,
    this.aadhaarFrontUrl,
    this.aadhaarBackUrl,
    this.aadhaarNumber,
    required this.kycStatus,
    this.kycSubmittedAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString() ?? '',
      selfieUrl: (json['livePhotoUrl'] ?? json['kycDetails']?['selfieUrl'])
          ?.toString(),
      aadhaarFrontUrl:
          (json['aadhaarImage'] ?? json['kycDetails']?['aadhaarFrontUrl'])
              ?.toString(),
      aadhaarBackUrl:
          (json['aadhaarBackImage'] ?? json['kycDetails']?['aadhaarBackUrl'])
              ?.toString(),
      aadhaarNumber:
          (json['aadhaarNumber'] ?? json['kycDetails']?['aadhaarNumber'])
              ?.toString(),
      kycStatus:
          (json['kycStatus'] ?? json['kycDetails']?['status'])?.toString() ??
              'pending',
      kycSubmittedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['kycDetails']?['submittedAt'] != null
              ? DateTime.tryParse(json['kycDetails']['submittedAt'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'phone': phone,
        'livePhotoUrl': selfieUrl,
        'aadhaarImage': aadhaarFrontUrl,
        'aadhaarBackImage': aadhaarBackUrl,
        'aadhaarNumber': aadhaarNumber,
        'kycStatus': kycStatus,
        'createdAt': kycSubmittedAt?.toIso8601String(),
      };
}
