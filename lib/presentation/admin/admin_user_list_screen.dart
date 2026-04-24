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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await _repo.getAllUsers();
      if (mounted) setState(() => _users = users);
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
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final user = _users[index];
          final color = _statusColor(user.subscriptionStatus);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(Icons.store, color: color),
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
                _loadUsers();
              },
            ),
          );
        },
      ),
    );
  }
}
