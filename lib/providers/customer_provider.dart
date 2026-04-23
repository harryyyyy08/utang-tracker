import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/customer_model.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/transaction_repository.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository());
final transactionRepositoryProvider = Provider((ref) => TransactionRepository());

// Provider para sa customer list
final customersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  final repo = ref.read(customerRepositoryProvider);
  final txRepo = ref.read(transactionRepositoryProvider);
  final customers = await repo.getCustomers();

  // I-compute ang total utang at overdue count ng bawat customer
  for (final customer in customers) {
    customer.totalUtang = await txRepo.getTotalUtang(customer.id);
    customer.overdueCount = await txRepo.getOverdueCount(customer.id);
  }

  return customers;
});

// Provider para sa total utang ng lahat
final totalUtangProvider = FutureProvider<double>((ref) async {
  final repo = ref.read(transactionRepositoryProvider);
  return await repo.getAllTotalUtang();
});

// Provider para sa monthly bayad collections (last 6 months)
final monthlyCollectionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final txRepo = ref.read(transactionRepositoryProvider);
  return txRepo.getMonthlyCollections();
});

// Search at filter state
final customerSearchQueryProvider = StateProvider<String>((ref) => '');
final customerFilterProvider = StateProvider<String>((ref) => 'all');

// Filtered customer list (client-side, walang bagong Supabase query)
final filteredCustomersProvider = Provider<AsyncValue<List<CustomerModel>>>((ref) {
  final customersAsync = ref.watch(customersProvider);
  final query = ref.watch(customerSearchQueryProvider).toLowerCase().trim();
  final filter = ref.watch(customerFilterProvider);

  return customersAsync.whenData((customers) {
    var list = query.isEmpty
        ? customers
        : customers.where((c) => c.name.toLowerCase().contains(query)).toList();

    if (filter == 'may_utang') {
      list = list.where((c) => c.totalUtang > 0).toList();
    } else if (filter == 'walang_utang') {
      list = list.where((c) => c.totalUtang <= 0).toList();
    }

    return list;
  });
});