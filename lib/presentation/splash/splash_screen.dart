import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/cache/hive_cache_service.dart';
import '../../core/connectivity/connectivity_service.dart';

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
      Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
    }
  }

  Future<void> _checkSubscription() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final isOnline = await ConnectivityService.instance.isOnline();

    Map<String, dynamic>? profile;

    if (isOnline) {
      try {
        profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (profile != null) {
          HiveCacheService.instance.saveProfileCache(userId, profile);
        }
      } catch (_) {
        // Network error even though "online" — fall back to cache
        profile = HiveCacheService.instance.loadProfileCache(userId);
      }
    } else {
      profile = HiveCacheService.instance.loadProfileCache(userId);
    }

    if (!mounted) return;

    if (profile == null) {
      if (isOnline) {
        // Profile doesn't exist — sign out
        await Supabase.instance.client.auth.signOut();
      }
      // No profile and no cache (or just offline with no prior data)
      Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
      return;
    }

    final role = profile['role'] as String? ?? 'user';

    if (role == 'admin') {
      Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
      return;
    }

    final status = profile['subscription_status'] as String? ?? 'trial';
    final expiryStr = profile['subscription_expiry'] as String?;

    if (status == 'active') {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      return;
    }

    if (expiryStr == null) {
      // Walang expiry — only block if we're online (cached data may be stale)
      if (isOnline) {
        Navigator.pushNamedAndRemoveUntil(context, '/subscription',
            (route) => false, arguments: true);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
      return;
    }

    final expiry = DateTime.parse(expiryStr).toUtc();
    final now = DateTime.now().toUtc();

    if (now.isBefore(expiry)) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      // Expired — only redirect to subscription screen when online
      if (isOnline) {
        Navigator.pushNamedAndRemoveUntil(context, '/subscription',
            (route) => false, arguments: true);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
                    color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
