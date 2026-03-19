import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await _checkSubscription();
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (route) => false);
    }
  }

  Future<void> _checkSubscription() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Force fresh data — hindi galing sa cache
      final response = await Supabase.instance.client
          .from('profiles')
          .select('subscription_status, subscription_expiry')
          .eq('id', userId)
          .single();

      final status = response['subscription_status'] as String;
      final expiryStr = response['subscription_expiry'] as String?;

      if (!mounted) return;

      // Active subscriber — tuloy sa home
      if (status == 'active') {
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (route) => false);
        return;
      }

      // Walang expiry
      if (expiryStr == null) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/subscription', (route) => false);
        return;
      }

      // UTC comparison
      final expiry = DateTime.parse(expiryStr).toUtc();
      final now = DateTime.now().toUtc();

      if (now.isBefore(expiry)) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/home', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(
            context, '/subscription', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text('Utang Tracker',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Para sa iyong tindahan',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}