class ProfileModel {
  final String id;
  final String? storeName;
  final String? ownerName;
  final String? phone;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiry;

  ProfileModel({
    required this.id,
    this.storeName,
    this.ownerName,
    this.phone,
    this.subscriptionStatus = 'trial',
    this.subscriptionExpiry,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      storeName: json['store_name'],
      ownerName: json['owner_name'],
      phone: json['phone'],
      subscriptionStatus: json['subscription_status'] ?? 'trial',
      subscriptionExpiry: json['subscription_expiry'] != null
          ? DateTime.parse(json['subscription_expiry'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_name': storeName,
      'owner_name': ownerName,
      'phone': phone,
    };
  }
}