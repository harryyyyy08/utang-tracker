import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/admin_repository.dart';
import 'admin_user_detail_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final _repo = AdminRepository();
  List<ProfileModel> _users = [];
  Set<String> _usersWithPendingPayment = {};
  int _pendingCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.getAllUsers(),
        _repo.getPendingPayments(),
      ]);
      final users = results[0] as List<ProfileModel>;
      final pending = results[1] as List<PaymentRequest>;
      if (mounted) {
        setState(() {
          _users = users;
          _pendingCount = pending.length;
          _usersWithPendingPayment = pending.map((p) => p.userId).toSet();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'trial':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'trial':
        return 'Trial';
      default:
        return 'Expired';
    }
  }

  String _formatExpiry(DateTime? expiry) {
    if (expiry == null) return 'Walang expiry';
    return DateFormat('MMM d, yyyy').format(expiry.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return const Center(child: Text('Walang registered users.'));
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length + (_pendingCount > 0 ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          // Pending payments banner at the top
          if (_pendingCount > 0 && index == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_pendingCount pending na bayad — i-tap ang user para ma-approve',
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }

          final userIndex = _pendingCount > 0 ? index - 1 : index;
          final user = _users[userIndex];
          final color = _statusColor(user.subscriptionStatus);
          final hasPending = _usersWithPendingPayment.contains(user.id);
          return Card(
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(Icons.store, color: color),
                  ),
                  if (hasPending)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                user.storeName ?? '(Walang store name)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.ownerName != null)
                    Text(user.ownerName!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel(user.subscriptionStatus),
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatExpiry(user.subscriptionExpiry),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUserDetailScreen(user: user),
                  ),
                );
                await _loadUsers();
              },
            ),
          );
        },
      ),
    );
  }
}
