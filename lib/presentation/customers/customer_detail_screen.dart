import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import 'add_transaction_screen.dart';
import 'edit_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final CustomerModel customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _repo = TransactionRepository();
  List<TransactionModel> _transactions = [];
  double _totalUtang = 0;
  bool _isLoading = true;
  final _formatter = NumberFormat('#,##0.00', 'en_PH');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _repo.getTransactions(widget.customer.id);
      final total = await _repo.getTotalUtang(widget.customer.id);
      setState(() {
        _transactions = transactions;
        _totalUtang = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditCustomerScreen(customer: widget.customer),
                ),
              );
              if (updated == true) _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Total Utang Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: _totalUtang > 0
                ? const Color(0xFFE53935)
                : const Color(0xFF43A047),
            child: Column(
              children: [
                const Text('Kabuuang Utang',
                    style: TextStyle(color: Colors.white70)),
                Text(
                  '₱${_formatter.format(_totalUtang)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _transactions.isEmpty
                ? const Center(
                child: Text('Wala pang transactions',
                    style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final t = _transactions[index];
                final isUtang = t.type == 'utang';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUtang
                          ? const Color(0xFFE53935)
                          : const Color(0xFF43A047),
                      child: Icon(
                        isUtang
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      isUtang ? 'Utang' : 'Bayad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUtang
                            ? const Color(0xFFE53935)
                            : const Color(0xFF43A047),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.description != null) Text(t.description!),
                        if (t.interestAmount > 0)
                          Text(
                            'Principal: ₱${_formatter.format(t.amount)} + '
                                'Interest: ₱${_formatter.format(t.interestAmount)} '
                                '(${(t.interestAmount / t.amount * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.orange),
                          ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(t.date),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${isUtang ? '+' : '-'}₱${_formatter.format(
                          isUtang ? t.totalWithInterest : t.amount)}',
                      style: TextStyle(
                        color: isUtang
                            ? const Color(0xFFE53935)
                            : const Color(0xFF43A047),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'utang',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(
                    customer: widget.customer,
                    initialType: 'utang',
                  ),
                ),
              );
              _loadData();
            },
            backgroundColor: const Color(0xFFE53935),
            icon: const Icon(Icons.add, color: Colors.white),
            label:
            const Text('Utang', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'bayad',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(
                    customer: widget.customer,
                    initialType: 'bayad',
                  ),
                ),
              );
              _loadData();
            },
            backgroundColor: const Color(0xFF43A047),
            icon: const Icon(Icons.check, color: Colors.white),
            label:
            const Text('Bayad', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}