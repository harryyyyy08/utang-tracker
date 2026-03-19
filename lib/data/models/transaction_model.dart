class TransactionModel {
  final String id;
  final String customerId;
  final String userId;
  final String type;
  final double amount;
  final double interestAmount; // ← bago
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.customerId,
    required this.userId,
    required this.type,
    required this.amount,
    this.interestAmount = 0,
    this.description,
    required this.date,
    required this.createdAt,
  });

  // Total amount kasama ang interest
  double get totalWithInterest => amount + interestAmount;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      customerId: json['customer_id'],
      userId: json['user_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      interestAmount:
      (json['interest_amount'] as num?)?.toDouble() ?? 0,
      description: json['description'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}