class RatingModel {
  final String id;
  final String jobId;
  final String raterId;
  final String ratedUserId;
  final String raterRole;
  final int score;
  final String comment;
  final DateTime createdAt;
  final String raterName;

  RatingModel({
    required this.id,
    required this.jobId,
    required this.raterId,
    required this.ratedUserId,
    required this.raterRole,
    required this.score,
    required this.comment,
    required this.createdAt,
    this.raterName = 'User',
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['_id'] ?? '',
      jobId: json['jobId']?['_id'] ?? json['jobId'] ?? '',
      raterId: json['raterId']?['_id'] ?? json['raterId'] ?? '',
      ratedUserId: json['ratedUserId'] ?? '',
      raterRole: json['raterRole'] ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      comment: json['comment'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      raterName: json['raterId']?['name'] ?? 'User',
    );
  }
}
