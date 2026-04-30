class ProfileModel {
  final String id;
  final String? storeName;
  final String? ownerName;
  final String? phone;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiry;
  final String role;
  final String? referralCode;
  final String? referredBy;
  final bool referralRewardPaid;

  ProfileModel({
    required this.id,
    this.storeName,
    this.ownerName,
    this.phone,
    this.subscriptionStatus = 'trial',
    this.subscriptionExpiry,
    this.role = 'user',
    this.referralCode,
    this.referredBy,
    this.referralRewardPaid = false,
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
      role: json['role'] ?? 'user',
      referralCode: json['referral_code'],
      referredBy: json['referred_by'],
      referralRewardPaid: json['referral_reward_paid'] as bool? ?? false,
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