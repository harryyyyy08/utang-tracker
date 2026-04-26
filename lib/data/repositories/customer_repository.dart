import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';
import '../../core/cache/hive_cache_service.dart';
import '../../core/connectivity/connectivity_service.dart';

class CustomerRepository {
  final _supabase = Supabase.instance.client;

  Future<List<CustomerModel>> getCustomers() async {
    final userId = _supabase.auth.currentUser!.id;
    final isOnline = await ConnectivityService.instance.isOnline();

    if (isOnline) {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('user_id', userId)
          .order('name');
      HiveCacheService.instance.saveCustomers(userId, response as List);
      return (response).map((json) => CustomerModel.fromJson(json)).toList();
    } else {
      final cached = HiveCacheService.instance.loadCustomers(userId);
      if (cached != null) {
        return cached.map((json) => CustomerModel.fromJson(json)).toList();
      }
      throw Exception('Offline at walang naka-save na data.');
    }
  }

  Future<CustomerModel> addCustomer({
    required String name,
    String? phone,
    String? address,
    String? notes,
    double interestRate = 0,
    double? creditLimit,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('customers').insert({
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'interest_rate': interestRate,
      'credit_limit': creditLimit,
    }).select().single();

    return CustomerModel.fromJson(response);
  }

  Future<void> deleteCustomer(String customerId) async {
    await _supabase.from('customers').delete().eq('id', customerId);
  }

  Future<void> updateCustomer({
    required String customerId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    double interestRate = 0,
    double? creditLimit,
  }) async {
    await _supabase.from('customers').update({
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'interest_rate': interestRate,
      'credit_limit': creditLimit,
    }).eq('id', customerId);
  }
}
