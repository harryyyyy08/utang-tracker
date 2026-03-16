import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/transaction_repository.dart';

class AddTransactionScreen extends StatefulWidget {
  final CustomerModel customer;
  final String initialType;

  const AddTransactionScreen({
    super.key,
    required this.customer,
    required this.initialType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedType;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  double _currentUtang = 0;
  bool _isLoadingUtang = true;
  final _repo = TransactionRepository();
  final _formatter = NumberFormat('#,##0.00', 'en_PH');

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _loadCurrentUtang();
  }

  // Kunin ang current utang ng customer
  Future<void> _loadCurrentUtang() async {
    final total = await _repo.getTotalUtang(widget.customer.id);
    if (mounted) {
      setState(() {
        _currentUtang = total;
        _isLoadingUtang = false;
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

  Future<void> _save() async {
    if (_amountController.text.isEmpty) {
      _showError('Ilagay ang halaga');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Hindi valid ang halaga');
      return;
    }

    // Validation para sa bayad
    if (_selectedType == 'bayad') {
      if (_currentUtang <= 0) {
        _showError('Wala nang utang si ${widget.customer.name}');
        return;
      }
      if (amount > _currentUtang) {
        _showError(
            'Ang bayad (₱${_formatter.format(amount)}) ay higit sa utang (₱${_formatter.format(_currentUtang)})'
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await _repo.addTransaction(
        customerId: widget.customer.id,
        type: _selectedType,
        amount: amount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        date: _selectedDate,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUtang = _selectedType == 'utang';
    final isBayadDisabled = _selectedType == 'bayad' && _currentUtang <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isUtang ? 'Utang' : 'Bayad'} - ${widget.customer.name}'),
        backgroundColor:
        isUtang ? const Color(0xFFE53935) : const Color(0xFF43A047),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingUtang
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Current Utang Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentUtang > 0
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentUtang > 0
                      ? const Color(0xFFE53935)
                      : const Color(0xFF43A047),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _currentUtang > 0
                        ? Icons.info_outline
                        : Icons.check_circle_outline,
                    color: _currentUtang > 0
                        ? const Color(0xFFE53935)
                        : const Color(0xFF43A047),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentUtang > 0
                        ? 'Kasalukuyang utang: ₱${_formatter.format(_currentUtang)}'
                        : 'Walang utang si ${widget.customer.name}',
                    style: TextStyle(
                      color: _currentUtang > 0
                          ? const Color(0xFFE53935)
                          : const Color(0xFF43A047),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Disabled notice kung walang utang at bayad ang pinili
            if (isBayadDisabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hindi pwedeng mag-bayad kung walang utang',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            if (isBayadDisabled) const SizedBox(height: 16),

            // Type Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = 'utang'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == 'utang'
                            ? const Color(0xFFE53935)
                            : Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Utang',
                          style: TextStyle(
                            color: _selectedType == 'utang'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = 'bayad'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == 'bayad'
                            ? const Color(0xFF43A047)
                            : Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Bayad',
                          style: TextStyle(
                            color: _selectedType == 'bayad'
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount
            TextField(
              controller: _amountController,
              enabled: !isBayadDisabled,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _selectedType == 'bayad'
                    ? 'Halaga (₱) — Max: ₱${_formatter.format(_currentUtang)}'
                    : 'Halaga (₱) *',
                prefixIcon: const Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              enabled: !isBayadDisabled,
              decoration: const InputDecoration(
                labelText: 'Dahilan / Description',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Petsa'),
              subtitle:
              Text(DateFormat('MMMM dd, yyyy').format(_selectedDate)),
              onTap: isBayadDisabled ? null : _pickDate,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: (_isLoading || isBayadDisabled) ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: isUtang
                    ? const Color(0xFFE53935)
                    : const Color(0xFF43A047),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                isBayadDisabled
                    ? 'Walang utang'
                    : 'I-save ang ${isUtang ? 'Utang' : 'Bayad'}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}