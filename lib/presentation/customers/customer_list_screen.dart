import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/customer_provider.dart';
import '../../data/repositories/customer_repository.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    _loadHintState();
  }

  Future<void> _loadHintState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('swipe_hint_dismissed') ?? false;
    if (mounted) setState(() => _showSwipeHint = !dismissed);
  }

  Future<void> _dismissHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('swipe_hint_dismissed', true);
    if (mounted) setState(() => _showSwipeHint = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredCustomersProvider);
    final currentFilter = ref.watch(customerFilterProvider);
    final formatter = NumberFormat('#,##0.00', 'en_PH');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) =>
                      ref.read(customerSearchQueryProvider.notifier).state =
                          value,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Maghanap ng customer...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(customerSearchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Filter chips
              Padding(
                padding:
                    const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Lahat',
                      selected: currentFilter == 'all',
                      onTap: () => ref
                          .read(customerFilterProvider.notifier)
                          .state = 'all',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'May Utang',
                      selected: currentFilter == 'may_utang',
                      onTap: () => ref
                          .read(customerFilterProvider.notifier)
                          .state = 'may_utang',
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Bayad Na',
                      selected: currentFilter == 'walang_utang',
                      onTap: () => ref
                          .read(customerFilterProvider.notifier)
                          .state = 'walang_utang',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      body: filteredAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            final isFiltering = ref.read(customerSearchQueryProvider).isNotEmpty ||
                ref.read(customerFilterProvider) != 'all';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFiltering ? Icons.search_off : Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isFiltering
                        ? 'Walang customer na nahanap'
                        : 'Wala pang customers',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFiltering
                        ? 'Subukan ng ibang search o filter'
                        : 'I-tap ang + para magdagdag',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(customersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: customers.length + (_showSwipeHint ? 1 : 0),
              itemBuilder: (context, index) {
                // Swipe hint card as first item
                if (_showSwipeHint && index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swipe_left,
                            color: Color(0xFF1E88E5), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'I-swipe pakaliwa ang customer para mag-delete',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _dismissHint,
                          child: const Icon(Icons.close,
                              color: Color(0xFF1E88E5), size: 18),
                        ),
                      ],
                    ),
                  );
                }

                final customer =
                    customers[index - (_showSwipeHint ? 1 : 0)];

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
                    if (_showSwipeHint) _dismissHint();
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
                          if (customer.overdueCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${customer.overdueCount} overdue',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            Text(
                              customer.totalUtang > 0
                                  ? 'may utang'
                                  : 'bayad na',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.white54,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF1E88E5) : Colors.white,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
