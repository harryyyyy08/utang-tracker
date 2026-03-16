import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final _supabase = Supabase.instance.client;

  // Kumuha ng lahat ng customers ng current user
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

  // Magdagdag ng customer
  Future<CustomerModel> addCustomer({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('customers').insert({
      'user_id': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
    }).select().single();

    return CustomerModel.fromJson(response);
  }

  // Mag-delete ng customer
  Future<void> deleteCustomer(String customerId) async {
    await _supabase.from('customers').delete().eq('id', customerId);
  }
}