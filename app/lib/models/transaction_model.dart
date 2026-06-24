class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String status;
  final String? upiId;
  final String? adminNote;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.status,
    this.upiId,
    this.adminNote,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      upiId: json['upiId'],
      adminNote: json['adminNote'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
