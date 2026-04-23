import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/customer_provider.dart';
import '../../providers/subscription_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _blue = Color(0xFF1E88E5);
  static const _red = Color(0xFFE53935);
  static const _green = Color(0xFF43A047);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final totalUtangAsync = ref.watch(totalUtangProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final monthlyAsync = ref.watch(monthlyCollectionsProvider);
    final formatter = NumberFormat('#,##0.00', 'en_PH');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customersProvider);
          ref.invalidate(totalUtangProvider);
          ref.invalidate(subscriptionProvider);
          ref.invalidate(monthlyCollectionsProvider);
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
                          const Icon(Icons.warning_amber, color: Colors.orange),
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
                              arguments: false,
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
                  color: _red,
                ),
                loading: () => _buildSummaryCard(
                  title: 'Kabuuang Utang',
                  value: 'Loading...',
                  icon: Icons.account_balance_wallet,
                  color: _red,
                ),
                error: (e, _) => _buildSummaryCard(
                  title: 'Kabuuang Utang',
                  value: 'Error',
                  icon: Icons.account_balance_wallet,
                  color: _red,
                ),
              ),
              const SizedBox(height: 12),

              // Customer Count Card
              customersAsync.when(
                data: (customers) => _buildSummaryCard(
                  title: 'Bilang ng Customers',
                  value: '${customers.length} customers',
                  icon: Icons.people,
                  color: _blue,
                ),
                loading: () => _buildSummaryCard(
                  title: 'Bilang ng Customers',
                  value: 'Loading...',
                  icon: Icons.people,
                  color: _blue,
                ),
                error: (e, _) => _buildSummaryCard(
                  title: 'Bilang ng Customers',
                  value: 'Error',
                  icon: Icons.people,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 24),

              // ── Top Debtors Bar Chart ──────────────────────────────
              const Text('Pinaka-malaking Utang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              customersAsync.when(
                data: (customers) {
                  final sorted = [...customers]
                    ..sort((a, b) => b.totalUtang.compareTo(a.totalUtang));
                  final top = sorted
                      .where((c) => c.totalUtang > 0)
                      .take(5)
                      .toList();

                  if (top.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Wala pang utang',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  final maxY = top.first.totalUtang * 1.2;

                  return Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: Colors.grey.withOpacity(0.15),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final name = top[group.x].name;
                                return BarTooltipItem(
                                  '$name\n₱${NumberFormat('#,##0', 'en_PH').format(rod.toY)}',
                                  const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= top.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final name = top[i].name.split(' ').first;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      name.length > 7
                                          ? '${name.substring(0, 6)}.'
                                          : name,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(top.length, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: top[i].totalUtang,
                                  color: _red,
                                  width: 28,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 24),

              // ── Monthly Collections Bar Chart ─────────────────────
              const Text('Bayad ng Nakalipas na 6 Buwan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              monthlyAsync.when(
                data: (data) {
                  final hasData = data.any((m) => (m['total'] as double) > 0);
                  final maxY = hasData
                      ? data
                              .map((m) => m['total'] as double)
                              .reduce((a, b) => a > b ? a : b) *
                          1.2
                      : 1000.0;

                  final monthLabels = ['', 'Ene', 'Peb', 'Mar', 'Abr', 'May',
                      'Hun', 'Hul', 'Ago', 'Set', 'Okt', 'Nob', 'Dis'];

                  return Container(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: Colors.grey.withOpacity(0.15),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                final monthKey =
                                    data[group.x]['month'] as String;
                                final parts = monthKey.split('-');
                                final label =
                                    '${monthLabels[int.parse(parts[1])]} ${parts[0]}';
                                return BarTooltipItem(
                                  '$label\n₱${NumberFormat('#,##0', 'en_PH').format(rod.toY)}',
                                  const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= data.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final monthKey =
                                      data[i]['month'] as String;
                                  final month =
                                      int.parse(monthKey.split('-')[1]);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      monthLabels[month],
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(data.length, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: data[i]['total'] as double,
                                  color: _green,
                                  width: 28,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 16),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
