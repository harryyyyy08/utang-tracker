import 'package:flutter/material.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

class EditCustomerScreen extends StatefulWidget {
  final CustomerModel customer;
  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late TextEditingController _interestRateController;
  late TextEditingController _creditLimitController;
  bool _isLoading = false;
  final _repo = CustomerRepository();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone ?? '');
    _addressController =
        TextEditingController(text: widget.customer.address ?? '');
    _notesController = TextEditingController(text: widget.customer.notes ?? '');
    _interestRateController = TextEditingController(
      text: widget.customer.interestRate > 0
          ? widget.customer.interestRate.toString()
          : '',
    );
    _creditLimitController = TextEditingController(
      text: widget.customer.creditLimit != null
          ? widget.customer.creditLimit!.toStringAsFixed(
              widget.customer.creditLimit! % 1 == 0 ? 0 : 2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _interestRateController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kailangan ng pangalan ng customer')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repo.updateCustomer(
        customerId: widget.customer.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        interestRate: double.tryParse(_interestRateController.text) ?? 0,
        creditLimit: _creditLimitController.text.trim().isEmpty
            ? null
            : double.tryParse(_creditLimitController.text),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        title: const Text('I-edit ang Customer'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Pangalan *',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _interestRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Interest Rate (%) — optional',
                hintText: 'Ex: 10 para sa 10%',
                prefixIcon: Icon(Icons.percent),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _creditLimitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Credit Limit (₱) — optional',
                hintText: 'Ex: 500 — max utang na pwede',
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('I-save ang Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
