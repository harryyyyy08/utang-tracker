class TransactionModel {
  final String id;
  final String customerId;
  final String userId;
  final String type;
  final double amount;
  final double interestAmount;
  final String? description;
  final DateTime date;
  final DateTime? dueDate;
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
    this.dueDate,
    required this.createdAt,
  });

  double get totalWithInterest => amount + interestAmount;

  bool get isOverdue =>
      type == 'utang' &&
      dueDate != null &&
      dueDate!.isBefore(DateTime.now());

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      customerId: json['customer_id'],
      userId: json['user_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      interestAmount: (json['interest_amount'] as num?)?.toDouble() ?? 0,
      description: json['description'],
      date: DateTime.parse(json['date']),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
