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

  // I-compute ang total utang ng bawat customer
  for (final customer in customers) {
    customer.totalUtang = await txRepo.getTotalUtang(customer.id);
  }

  return customers;
});

// Provider para sa total utang ng lahat
final totalUtangProvider = FutureProvider<double>((ref) async {
  final repo = ref.read(transactionRepositoryProvider);
  return await repo.getAllTotalUtang();
});