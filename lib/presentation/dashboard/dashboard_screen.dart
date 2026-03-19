import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/customer_provider.dart';
import '../../providers/subscription_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final totalUtangAsync = ref.watch(totalUtangProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final formatter = NumberFormat('#,##0.00', 'en_PH');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customersProvider);
          ref.invalidate(totalUtangProvider);
          ref.invalidate(subscriptionProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Trial Banner
              subAsync.when(
                data: (sub) {
                  if (sub.status == SubscriptionStatus.trial &&
                      sub.daysRemaining <= 7) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sub.daysRemaining == 0
                                  ? 'Mag-e-expire na ang trial mo ngayon!'
                                  : '${sub.daysRemaining} araw na lang ang trial mo!',
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/subscription',
                              arguments: false, // ← hindi pa expired, trial pa lang
                            ),
                            child: const Text('Mag-subscribe'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Total Utang Card
              totalUtangAsync.when(
                data: (total) => _buildSummaryCard(
                  title: 'Kabuuang Utang',
                  value: '₱${formatter.format(total)}',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFFE53935),
                ),
                loading: () => _buildSummaryCard(
                  title: 'Kabuuang Utang',
                  value: 'Loading...',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFFE53935),
                ),
                error: (e, _) => _buildSummaryCard(
                  title: 'Kabuuang Utang',
                  value: 'Error',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 12),

              // Customer Count Card
              customersAsync.when(
                data: (customers) => _buildSummaryCard(
                  title: 'Bilang ng Customers',
                  value: '${customers.length} customers',
                  icon: Icons.people,
                  color: const Color(0xFF1E88E5),
                ),
                loading: () => _buildSummaryCard(
                  title: 'Bilang ng Customers',
                  value: 'Loading...',
                  icon: Icons.people,
                  color: const Color(0xFF1E88E5),
                ),
                error: (e, _) => _buildSummaryCard(
                  title: 'Bilang ng Customers',
                  value: 'Error',
                  icon: Icons.people,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 24),

              // Top Utang
              const Text('Pinaka-malaking Utang',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              customersAsync.when(
                data: (customers) {
                  final sorted = [...customers]
                    ..sort(
                            (a, b) => b.totalUtang.compareTo(a.totalUtang));
                  final top = sorted.take(5).toList();

                  if (top.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Wala pang customers',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: top.length,
                    itemBuilder: (context, index) {
                      final customer = top[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1E88E5),
                            child: Text(
                              customer.name[0].toUpperCase(),
                              style:
                              const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(customer.name),
                          trailing: Text(
                            '₱${formatter.format(customer.totalUtang)}',
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}