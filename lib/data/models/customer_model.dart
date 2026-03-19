class CustomerModel {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final double interestRate; // ← bago
  final DateTime createdAt;
  double totalUtang;
  double totalInterest; // ← bago

  CustomerModel({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.interestRate = 0,
    required this.createdAt,
    this.totalUtang = 0,
    this.totalInterest = 0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      notes: json['notes'],
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}