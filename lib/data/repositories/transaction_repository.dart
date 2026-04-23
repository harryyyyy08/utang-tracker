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
    double interestAmount = 0,
    String? description,
    required DateTime date,
    DateTime? dueDate,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase.from('transactions').insert({
      'customer_id': customerId,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'interest_amount': interestAmount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
    }).select().single();

    return TransactionModel.fromJson(response);
  }

  // Bilang ng overdue transactions ng isang customer
  Future<int> getOverdueCount(String customerId) async {
    final transactions = await getTransactions(customerId);
    return transactions.where((t) => t.isOverdue).length;
  }

  // I-update ang isang transaction
  Future<void> updateTransaction({
    required String transactionId,
    required double amount,
    double interestAmount = 0,
    String? description,
    required DateTime date,
    DateTime? dueDate,
  }) async {
    await _supabase.from('transactions').update({
      'amount': amount,
      'interest_amount': interestAmount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
    }).eq('id', transactionId);
  }

  // I-delete ang isang transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _supabase.from('transactions').delete().eq('id', transactionId);
  }

  // Kumuha ng total utang ng isang customer
  Future<double> getTotalUtang(String customerId) async {
    final transactions = await getTransactions(customerId);
    double total = 0;
    for (final t in transactions) {
      if (t.type == 'utang') {
        total += t.amount + t.interestAmount;
      } else {
        total -= t.amount;
      }
    }
    return total < 0 ? 0 : total;
  }

  // Kumuha ng monthly bayad totals (last 6 months)
  Future<List<Map<String, dynamic>>> getMonthlyCollections() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    final response = await _supabase
        .from('transactions')
        .select('amount, date')
        .eq('user_id', userId)
        .eq('type', 'bayad')
        .gte('date', sixMonthsAgo.toIso8601String().split('T')[0]);

    final Map<String, double> totals = {};
    for (final t in response as List) {
      final date = DateTime.parse(t['date']);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      totals[key] = (totals[key] ?? 0) + (t['amount'] as num).toDouble();
    }

    // Fill in missing months with 0
    final result = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      result.add({'month': key, 'total': totals[key] ?? 0.0});
    }

    return result;
  }

  // Kumuha ng total utang ng lahat ng customers
  Future<double> getAllTotalUtang() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('transactions')
        .select('type, amount, interest_amount')
        .eq('user_id', userId);

    double total = 0;
    for (final t in response as List) {
      final amount = (t['amount'] as num).toDouble();
      final interest = (t['interest_amount'] as num?)?.toDouble() ?? 0;
      if (t['type'] == 'utang') {
        total += amount + interest;
      } else {
        total -= amount;
      }
    }
    return total < 0 ? 0 : total;
  }
}