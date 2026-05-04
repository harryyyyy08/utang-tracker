import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class PaymentRequest {
  final String id;
  final String userId;
  final String paymentCode;
  final String? gcashTransactionId;
  final DateTime createdAt;

  PaymentRequest({
    required this.id,
    required this.userId,
    required this.paymentCode,
    this.gcashTransactionId,
    required this.createdAt,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) => PaymentRequest(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        paymentCode: json['payment_code'] as String,
        gcashTransactionId: json['gcash_transaction_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class AdminRepository {
  final _client = Supabase.instance.client;

  Future<List<ProfileModel>> getAllUsers() async {
    final data = await _client
        .from('profiles')
        .select()
        .neq('role', 'admin')
        .order('created_at', ascending: false);

    return (data as List).map((e) => ProfileModel.fromJson(e)).toList();
  }

  Future<void> activateSubscription(String userId) async {
    final data = await _client
        .from('profiles')
        .select('referred_by, referral_reward_paid')
        .eq('id', userId)
        .single();

    final referrerId = data['referred_by'] as String?;
    final rewardPaid = data['referral_reward_paid'] as bool? ?? false;
    final hasUnpaidReferral = referrerId != null && !rewardPaid;

    final now = DateTime.now().toUtc();
    // Referred user (first subscription): 60 days. Normal: 30 days.
    final expiry = hasUnpaidReferral
        ? DateTime(now.year, now.month + 2, now.day,
                now.hour, now.minute, now.second)
            .toUtc()
        : now.add(const Duration(days: 30));

    await _client.from('profiles').update({
      'subscription_status': 'active',
      'subscription_expiry': expiry.toIso8601String(),
      if (hasUnpaidReferral) 'referral_reward_paid': true,
    }).eq('id', userId);

    if (hasUnpaidReferral) {
      final ref = await _client
          .from('profiles')
          .select('subscription_expiry, subscription_status')
          .eq('id', referrerId!)
          .single();

      final refStatus = ref['subscription_status'] as String;
      final refExpiryStr = ref['subscription_expiry'] as String?;
      final refBase =
          (refExpiryStr != null &&
                  DateTime.parse(refExpiryStr).toUtc().isAfter(now))
              ? DateTime.parse(refExpiryStr).toUtc()
              : now;
      final refNewExpiry = DateTime(refBase.year, refBase.month + 1,
              refBase.day, refBase.hour, refBase.minute, refBase.second)
          .toUtc();

      await _client.from('profiles').update({
        'subscription_status':
            refStatus == 'expired' ? 'trial' : refStatus,
        'subscription_expiry': refNewExpiry.toIso8601String(),
      }).eq('id', referrerId);
    }
  }

  Future<void> extendSubscription(String userId, int months) async {
    final data = await _client
        .from('profiles')
        .select('subscription_expiry, subscription_status')
        .eq('id', userId)
        .single();

    final status = data['subscription_status'] as String;
    final expiryStr = data['subscription_expiry'] as String?;

    DateTime base;
    if (status == 'active' && expiryStr != null) {
      base = DateTime.parse(expiryStr).toUtc();
      // If already expired, start from today
      if (base.isBefore(DateTime.now().toUtc())) {
        base = DateTime.now().toUtc();
      }
    } else {
      base = DateTime.now().toUtc();
    }

    final newExpiry = DateTime(
      base.year,
      base.month + months,
      base.day,
      base.hour,
      base.minute,
      base.second,
    ).toUtc();

    await _client.from('profiles').update({
      'subscription_status': 'active',
      'subscription_expiry': newExpiry.toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> deactivateSubscription(String userId) async {
    final expired = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
    await _client.from('profiles').update({
      'subscription_status': 'expired',
      'subscription_expiry': expired.toIso8601String(),
    }).eq('id', userId);
  }

  Future<List<PaymentRequest>> getPendingPayments() async {
    final data = await _client
        .from('payments')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return (data as List).map((e) => PaymentRequest.fromJson(e)).toList();
  }

  Future<List<PaymentRequest>> getPendingPaymentsForUser(String userId) async {
    final data = await _client
        .from('payments')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (data as List).map((e) => PaymentRequest.fromJson(e)).toList();
  }

  Future<void> approvePayment(String paymentId, String userId) async {
    await _client
        .from('payments')
        .update({'status': 'approved'})
        .eq('id', paymentId);
    await activateSubscription(userId);
  }

  Future<void> rejectPayment(String paymentId) async {
    await _client
        .from('payments')
        .update({'status': 'rejected'})
        .eq('id', paymentId);
  }

  /// Restores the user's trial period based on their original signup date.
  /// Trial = created_at + 14 days. If that date has already passed, gives
  /// them 14 fresh days from today instead.
  Future<void> restoreToTrial(String userId) async {
    final data = await _client
        .from('profiles')
        .select('created_at')
        .eq('id', userId)
        .single();

    final createdAt = DateTime.parse(data['created_at'] as String).toUtc();
    final originalExpiry = createdAt.add(const Duration(days: 14));
    final now = DateTime.now().toUtc();

    // If original trial already passed, give 14 fresh days
    final expiry =
        originalExpiry.isAfter(now) ? originalExpiry : now.add(const Duration(days: 14));

    await _client.from('profiles').update({
      'subscription_status': 'trial',
      'subscription_expiry': expiry.toIso8601String(),
    }).eq('id', userId);
  }
}
