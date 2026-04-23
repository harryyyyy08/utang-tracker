import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final _supabase = Supabase.instance.client;

  Future<List<CustomerModel>> getCustomers() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('customers')
        .select()
        .eq('user_id', userId)
        .order('name');

    return (response as List)
        .map((json) => CustomerModel.fromJson(json))
        .toList();
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
