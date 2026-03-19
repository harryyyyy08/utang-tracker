import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/dashboard_screen.dart';
import '../customers/customer_list_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/customer_provider.dart';
import '../../providers/subscription_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {  // ← para ma-detect ang app resume
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CustomerListScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // I-check ang subscription sa startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscription();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // I-check kapag nag-resume ang app mula sa background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSubscription();
    }
  }

  Future<void> _checkSubscription() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('subscription_status, subscription_expiry')
          .eq('id', userId)
          .single();

      final status = response['subscription_status'] as String;
      final expiryStr = response['subscription_expiry'] as String?;

      if (!mounted) return;

      // Active — okay, tuloy
      if (status == 'active') return;

      // I-check ang expiry
      if (expiryStr == null) {
        _redirectToSubscription();
        return;
      }

      final expiry = DateTime.parse(expiryStr).toUtc();
      final now = DateTime.now().toUtc();

      if (now.isAfter(expiry)) {
        _redirectToSubscription();
      }
    } catch (e) {
      // Silent fail — hindi i-redirect para hindi maabala ang user
    }
  }

  void _redirectToSubscription() {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, '/subscription', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            ref.invalidate(customersProvider);
            ref.invalidate(totalUtangProvider);
            ref.invalidate(subscriptionProvider);
          }
        },
        selectedItemColor: const Color(0xFF1E88E5),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}