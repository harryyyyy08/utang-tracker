import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SubscriptionStatus { trial, active, expired }

class SubscriptionState {
  final SubscriptionStatus status;
  final DateTime? expiry;
  final int daysRemaining;

  SubscriptionState({
    required this.status,
    this.expiry,
    this.daysRemaining = 0,
  });
}

final subscriptionProvider = FutureProvider<SubscriptionState>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  final response = await supabase
      .from('profiles')
      .select('subscription_status, subscription_expiry')
      .eq('id', userId)
      .single();

  final status = response['subscription_status'] as String;
  final expiryStr = response['subscription_expiry'] as String?;
  final expiry = expiryStr != null ? DateTime.parse(expiryStr) : null;

  // Kung active, walang expiry check
  if (status == 'active') {
    return SubscriptionState(
      status: SubscriptionStatus.active,
      expiry: expiry,
      daysRemaining: 999,
    );
  }

  // Kung trial, i-check ang expiry
  if (expiry != null) {
    final now = DateTime.now().toUtc();
    final expiryUtc = expiry.toUtc();
    final daysRemaining = expiryUtc.difference(now).inDays;

    if (now.isAfter(expiryUtc)) {
      return SubscriptionState(
        status: SubscriptionStatus.expired,
        expiry: expiry,
        daysRemaining: 0,
      );
    }

    return SubscriptionState(
      status: SubscriptionStatus.trial,
      expiry: expiry,
      daysRemaining: daysRemaining,
    );
  }

  return SubscriptionState(status: SubscriptionStatus.expired);
});