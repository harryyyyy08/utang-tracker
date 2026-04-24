import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

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
    final expiry = DateTime.now().toUtc().add(const Duration(days: 30));
    await _client.from('profiles').update({
      'subscription_status': 'active',
      'subscription_expiry': expiry.toIso8601String(),
    }).eq('id', userId);
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
