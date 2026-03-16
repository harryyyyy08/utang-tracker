class CustomerModel {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  double totalUtang;

  CustomerModel({
    required this.id,
    required this.userId,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    required this.createdAt,
    this.totalUtang = 0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}