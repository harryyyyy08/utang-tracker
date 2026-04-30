import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;
  final CustomerModel customer;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
    required this.customer,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  DateTime? _dueDate;
  String? _selectedPaymentMethod;
  bool _isLoading = false;
  double _computedInterest = 0;
  final _repo = TransactionRepository();
  final _formatter = NumberFormat('#,##0.00', 'en_PH');

  bool get _isUtang => widget.transaction.type == 'utang';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: widget.transaction.amount.toStringAsFixed(
            widget.transaction.amount % 1 == 0 ? 0 : 2));
    _descriptionController =
        TextEditingController(text: widget.transaction.description ?? '');
    _selectedDate = widget.transaction.date;
    _dueDate = widget.transaction.dueDate;
    _selectedPaymentMethod = widget.transaction.paymentMethod;
    _computedInterest = widget.transaction.interestAmount;
    _amountController.addListener(_computeInterest);
  }

  @override
  void dispose() {
    _amountController.removeListener(_computeInterest);
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _computeInterest() {
    if (_isUtang) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      setState(() {
        _computedInterest = amount * (widget.customer.interestRate / 100);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Petsa ng dapat bayaran',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Hindi valid ang halaga'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repo.updateTransaction(
        transactionId: widget.transaction.id,
        amount: amount,
        interestAmount: _isUtang ? _computedInterest : 0,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
        dueDate: _isUtang ? _dueDate : null,
        paymentMethod: _isUtang ? null : _selectedPaymentMethod,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('I-edit ang ${_isUtang ? 'Utang' : 'Bayad'}'),
        backgroundColor:
            _isUtang ? const Color(0xFFE53935) : const Color(0xFF43A047),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Type indicator (read-only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isUtang
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _isUtang
                        ? const Color(0xFFE53935)
                        : const Color(0xFF43A047)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isUtang ? Icons.arrow_upward : Icons.arrow_downward,
                    color: _isUtang
                        ? const Color(0xFFE53935)
                        : const Color(0xFF43A047),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uri: ${_isUtang ? 'UTANG' : 'BAYAD'} (hindi mababago)',
                    style: TextStyle(
                      color: _isUtang
                          ? const Color(0xFFE53935)
                          : const Color(0xFF43A047),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Halaga (₱) *',
                prefixIcon: Icon(Icons.money),
              ),
            ),

            // Interest breakdown (utang with interest rate)
            if (_isUtang && widget.customer.interestRate > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Principal:'),
                        Text('₱${_formatter.format(double.tryParse(_amountController.text) ?? 0)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Interest (${widget.customer.interestRate}%):'),
                        Text('₱${_formatter.format(_computedInterest)}',
                            style: const TextStyle(color: Colors.orange)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '₱${_formatter.format((double.tryParse(_amountController.text) ?? 0) + _computedInterest)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE53935)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Dahilan / Description',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 16),

            // Mode of Payment (bayad only)
            if (!_isUtang) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mode of Payment (opsyonal)',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: TransactionModel.paymentMethods
                    .map((entry) => ChoiceChip(
                          label: Text(entry.$2,
                              style: const TextStyle(fontSize: 13)),
                          selected: _selectedPaymentMethod == entry.$1,
                          selectedColor: const Color(0xFF43A047),
                          labelStyle: TextStyle(
                            color: _selectedPaymentMethod == entry.$1
                                ? Colors.white
                                : null,
                          ),
                          onSelected: (selected) => setState(() {
                            _selectedPaymentMethod =
                                selected ? entry.$1 : null;
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Transaction Date
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Petsa ng Transaksyon'),
              subtitle:
                  Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
              onTap: _pickDate,
            ),

            // Due Date (utang only)
            if (_isUtang) ...[
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: _dueDate != null
                          ? Colors.orange
                          : Colors.grey[400]!),
                ),
                leading: Icon(
                  Icons.event_available,
                  color: _dueDate != null ? Colors.orange : null,
                ),
                title: const Text('Petsa ng Dapat Bayaran (opsyonal)'),
                subtitle: Text(
                  _dueDate != null
                      ? DateFormat('MMMM dd, yyyy').format(_dueDate!)
                      : 'Walang takdang petsa',
                  style: TextStyle(
                      color: _dueDate != null ? Colors.orange[700] : null),
                ),
                trailing: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                      )
                    : null,
                onTap: _pickDueDate,
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUtang
                      ? const Color(0xFFE53935)
                      : const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('I-save ang Pagbabago',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
