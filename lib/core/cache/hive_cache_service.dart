import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class HiveCacheService {
  static final HiveCacheService instance = HiveCacheService._();
  HiveCacheService._();

  late Box<String> _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>('app_cache');
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  void saveProfileCache(String userId, Map<String, dynamic> data) {
    _box.put('profile_$userId', jsonEncode(data));
  }

  Map<String, dynamic>? loadProfileCache(String userId) {
    final raw = _box.get('profile_$userId');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  // ── Customers ──────────────────────────────────────────────────────────────

  void saveCustomers(String userId, List data) {
    _box.put('customers_$userId', jsonEncode(data));
  }

  List<Map<String, dynamic>>? loadCustomers(String userId) {
    final raw = _box.get('customers_$userId');
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  void saveTransactions(String customerId, List data) {
    _box.put('transactions_$customerId', jsonEncode(data));
  }

  List<Map<String, dynamic>>? loadTransactions(String customerId) {
    final raw = _box.get('transactions_$customerId');
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ── Dashboard aggregates ───────────────────────────────────────────────────

  void saveTotalUtang(String userId, double value) {
    _box.put('total_utang_$userId', value.toString());
  }

  double? loadTotalUtang(String userId) {
    final raw = _box.get('total_utang_$userId');
    return raw != null ? double.tryParse(raw) : null;
  }

  void saveMonthlyCollections(String userId, List data) {
    _box.put('monthly_$userId', jsonEncode(data));
  }

  List<Map<String, dynamic>>? loadMonthlyCollections(String userId) {
    final raw = _box.get('monthly_$userId');
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  Future<void> clearAll() async => _box.clear();
}
