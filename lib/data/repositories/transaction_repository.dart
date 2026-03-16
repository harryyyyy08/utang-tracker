import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  // Kumuha ng transactions ng isang customer
  Future<List<TransactionModel>> getTransactions(String customerId) async {
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('customer_id', customerId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // Magdagdag ng transaction
  Future<TransactionModel> addTransaction({
    required String customerId,
    required String type,
    required double amount,
    String? description,
    required DateTime date,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('transactions').insert({
      'customer_id': customerId,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
    }).select().single();

    return TransactionModel.fromJson(response);
  }

  // Kumuha ng total utang ng isang customer
  Future<double> getTotalUtang(String customerId) async {
    final transactions = await getTransactions(customerId);
    double total = 0;
    for (final t in transactions) {
      if (t.type == 'utang') {
        total += t.amount;
      } else {
        total -= t.amount;
      }
    }
    return total < 0 ? 0 : total;
  }

  // Kumuha ng total utang ng lahat ng customers
  Future<double> getAllTotalUtang() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('transactions')
        .select('type, amount')
        .eq('user_id', userId);

    double total = 0;
    for (final t in response as List) {
      final amount = (t['amount'] as num).toDouble();
      if (t['type'] == 'utang') {
        total += amount;
      } else {
        total -= amount;
      }
    }
    return total < 0 ? 0 : total;
  }
}