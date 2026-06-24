class ReferredUserModel {
  final String name;
  final DateTime joinedDate;
  final String status;

  ReferredUserModel({
    required this.name,
    required this.joinedDate,
    required this.status,
  });

  factory ReferredUserModel.fromJson(Map<String, dynamic> json) {
    return ReferredUserModel(
      name: json['name'] ?? 'Unknown',
      joinedDate: DateTime.parse(
          json['joinedDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'active',
    );
  }
}
