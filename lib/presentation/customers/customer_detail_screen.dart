import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../providers/profile_provider.dart';
import 'add_transaction_screen.dart';
import 'edit_customer_screen.dart';
import 'edit_transaction_screen.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final CustomerModel customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  final _repo = TransactionRepository();
  List<TransactionModel> _transactions = [];
  double _totalUtang = 0;
  bool _isLoading = true;
  final _formatter = NumberFormat('#,##0.00', 'en_PH');
  final _dateFormat = DateFormat('MMM dd, yyyy');

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

  void _shareBalance() {
    final profile = ref.read(profileProvider).value;
    final storeName = profile?.storeName ?? 'Ang Aming Tindahan';
    final storePhone = profile?.phone ?? '';
    final today = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('📋 BALANSE NI ${widget.customer.name.toUpperCase()}');
    buffer.writeln('$storeName — $today');
    buffer.writeln();

    if (_totalUtang > 0) {
      buffer.writeln('💰 Kabuuang Utang: ₱${_formatter.format(_totalUtang)}');
    } else {
      buffer.writeln('✅ Walang natitirang utang!');
    }

    if (_transactions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📝 Kasaysayan ng Transaksyon:');
      for (final t in _transactions.take(10)) {
        final sign = t.type == 'utang' ? '➕' : '➖';
        final amount =
            t.type == 'utang' ? t.totalWithInterest : t.amount;
        final label = t.type == 'utang' ? 'UTANG' : 'BAYAD';
        final desc = t.description != null ? ' (${t.description})' : '';
        buffer.writeln(
            '$sign ${_dateFormat.format(t.date)} $label — ₱${_formatter.format(amount)}$desc');
        if (t.isOverdue) buffer.writeln('   ⚠️ OVERDUE');
      }
      if (_transactions.length > 10) {
        buffer.writeln('   ... at ${_transactions.length - 10} pa');
      }
    }

    if (storePhone.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📞 Para sa katanungan: $storePhone');
    }

    Share.share(buffer.toString(),
        subject: 'Balanse ni ${widget.customer.name}');
  }

  void _showTransactionOptions(TransactionModel t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${t.type == 'utang' ? 'Utang' : 'Bayad'} — ₱${_formatter.format(t.type == 'utang' ? t.totalWithInterest : t.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(_dateFormat.format(t.date),
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
              title: const Text('I-edit ang transaksyon'),
              onTap: () async {
                Navigator.pop(ctx);
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTransactionScreen(
                      transaction: t,
                      customer: widget.customer,
                    ),
                  ),
                );
                if (updated == true) _loadData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('I-delete ang transaksyon',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('I-delete ang Transaksyon?'),
                    content: const Text(
                        'Sigurado ka? Hindi na ito mababawi.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: const Text('I-delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _repo.deleteTransaction(t.id);
                  _loadData();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
            icon: const Icon(Icons.share),
            tooltip: 'I-share ang balanse',
            onPressed: _isLoading ? null : _shareBalance,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditCustomerScreen(customer: widget.customer),
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
                // ── Header ────────────────────────────────────────────
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
                      if (widget.customer.creditLimit != null &&
                          widget.customer.creditLimit! > 0) ...[
                        const SizedBox(height: 12),
                        _buildCreditLimitBar(),
                      ],
                    ],
                  ),
                ),

                // ── Transactions ───────────────────────────────────────
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Wala pang transactions',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 148),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final t = _transactions[index];
                            return _TransactionCard(
                              transaction: t,
                              formatter: _formatter,
                              dateFormat: _dateFormat,
                              onLongPress: () => _showTransactionOptions(t),
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
            label: const Text('Utang', style: TextStyle(color: Colors.white)),
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
            label: const Text('Bayad', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditLimitBar() {
    final limit = widget.customer.creditLimit!;
    final ratio = (_totalUtang / limit).clamp(0.0, 1.0);
    final Color barColor;
    final String limitLabel;

    if (ratio >= 1.0) {
      barColor = Colors.red[300]!;
      limitLabel = '⚠️ NALAMPASAN ANG CREDIT LIMIT!';
    } else if (ratio >= 0.7) {
      barColor = Colors.orange[300]!;
      limitLabel = 'Malapit na sa credit limit';
    } else {
      barColor = Colors.green[300]!;
      limitLabel = 'Credit Limit';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(limitLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              '₱${_formatter.format(_totalUtang)} / ₱${_formatter.format(limit)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ── Transaction Card (separate widget to fix ListTile overflow bug) ──────────
class _TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final NumberFormat formatter;
  final DateFormat dateFormat;
  final VoidCallback onLongPress;

  const _TransactionCard({
    required this.transaction,
    required this.formatter,
    required this.dateFormat,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isUtang = t.type == 'utang';
    final displayAmount =
        isUtang ? t.totalWithInterest : t.amount;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading avatar
              CircleAvatar(
                backgroundColor: isUtang
                    ? const Color(0xFFE53935)
                    : const Color(0xFF43A047),
                child: Icon(
                  isUtang ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content (takes remaining space)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row: type label + overdue badge
                    Row(
                      children: [
                        Text(
                          isUtang ? 'Utang' : 'Bayad',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isUtang
                                ? const Color(0xFFE53935)
                                : const Color(0xFF43A047),
                          ),
                        ),
                        if (t.isOverdue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OVERDUE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Description
                    if (t.description != null) ...[
                      const SizedBox(height: 2),
                      Text(t.description!,
                          style: const TextStyle(fontSize: 13)),
                    ],

                    // Interest breakdown
                    if (t.interestAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Principal: ₱${formatter.format(t.amount)} + '
                        'Interest: ₱${formatter.format(t.interestAmount)} '
                        '(${(t.interestAmount / t.amount * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.orange),
                      ),
                    ],

                    // Transaction date
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(t.date),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),

                    // Due date
                    if (t.dueDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Dapat bayaran: ${dateFormat.format(t.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              t.isOverdue ? Colors.red : Colors.orange[700],
                          fontWeight: t.isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],

                    // Long press hint
                    const SizedBox(height: 4),
                    const Text('Hold para i-edit o i-delete',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Amount (fixed width, right-aligned)
              SizedBox(
                width: 90,
                child: Text(
                  '${isUtang ? '+' : '-'}₱${formatter.format(displayAmount)}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: isUtang
                        ? const Color(0xFFE53935)
                        : const Color(0xFF43A047),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
