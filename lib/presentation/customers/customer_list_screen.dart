import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/customer_provider.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final formatter = NumberFormat('#,##0.00', 'en_PH');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
          ref.invalidate(customersProvider);
        },
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Wala pang customers',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('I-tap ang + para magdagdag',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];

                return Dismissible(
                  key: Key(customer.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('I-delete ang Customer?'),
                        content: Text(
                          'Sigurado ka bang gusto mong i-delete si ${customer.name}? '
                              'Matatanggal din ang lahat ng kanyang transactions.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('I-delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await CustomerRepository().deleteCustomer(customer.id);
                    ref.invalidate(customersProvider);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDetailScreen(customer: customer),
                          ),
                        );
                        ref.invalidate(customersProvider);
                      },
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1E88E5),
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(customer.name,
                          style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: customer.phone != null
                          ? Text(customer.phone!)
                          : null,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${formatter.format(customer.totalUtang)}',
                            style: TextStyle(
                              color: customer.totalUtang > 0
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF43A047),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            customer.totalUtang > 0 ? 'may utang' : 'bayad na',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}