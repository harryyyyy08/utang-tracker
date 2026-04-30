import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../../core/cache/hive_cache_service.dart';
import '../../core/connectivity/connectivity_service.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  Future<List<TransactionModel>> getTransactions(String customerId) async {
    final isOnline = await ConnectivityService.instance.isOnline();

    if (isOnline) {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('customer_id', customerId)
          .order('date', ascending: false)
          .order('created_at', ascending: false);
      HiveCacheService.instance.saveTransactions(customerId, response as List);
      return (response).map((json) => TransactionModel.fromJson(json)).toList();
    } else {
      final cached = HiveCacheService.instance.loadTransactions(customerId);
      if (cached != null) {
        return cached.map((json) => TransactionModel.fromJson(json)).toList();
      }
      return []; // No cache yet for this customer — return empty
    }
  }

  Future<TransactionModel> addTransaction({
    required String customerId,
    required String type,
    required double amount,
    double interestAmount = 0,
    String? description,
    required DateTime date,
    DateTime? dueDate,
    String? paymentMethod,
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
      if (paymentMethod != null) 'payment_method': paymentMethod,
    }).select().single();

    return TransactionModel.fromJson(response);
  }

  Future<int> getOverdueCount(String customerId) async {
    final transactions = await getTransactions(customerId);
    return transactions.where((t) => t.isOverdue).length;
  }

  Future<void> updateTransaction({
    required String transactionId,
    required double amount,
    double interestAmount = 0,
    String? description,
    required DateTime date,
    DateTime? dueDate,
    String? paymentMethod,
  }) async {
    await _supabase.from('transactions').update({
      'amount': amount,
      'interest_amount': interestAmount,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
    }).eq('id', transactionId);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('user_id', userId);
  }

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

  Future<List<Map<String, dynamic>>> getMonthlyCollections() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final isOnline = await ConnectivityService.instance.isOnline();

    if (isOnline) {
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

      final result = <Map<String, dynamic>>[];
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(DateTime.now().year, DateTime.now().month - i, 1);
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        result.add({'month': key, 'total': totals[key] ?? 0.0});
      }

      HiveCacheService.instance.saveMonthlyCollections(userId, result);
      return result;
    } else {
      return HiveCacheService.instance.loadMonthlyCollections(userId) ?? [];
    }
  }

  Future<double> getAllTotalUtang() async {
    final userId = _supabase.auth.currentUser!.id;
    final isOnline = await ConnectivityService.instance.isOnline();

    if (isOnline) {
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
      final result = total < 0 ? 0.0 : total;
      HiveCacheService.instance.saveTotalUtang(userId, result);
      return result;
    } else {
      return HiveCacheService.instance.loadTotalUtang(userId) ?? 0.0;
    }
  }
}
