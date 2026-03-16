class TransactionModel {
  final String id;
  final String customerId;
  final String userId;
  final String type; // 'utang' or 'bayad'
  final double amount;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.customerId,
    required this.userId,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      customerId: json['customer_id'],
      userId: json['user_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}