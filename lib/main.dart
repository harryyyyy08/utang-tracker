import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'core/theme/app_theme.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/subscription/subscription_screen.dart';
import 'presentation/auth/reset_password_screen.dart';
import 'presentation/admin/admin_home_screen.dart';
import 'presentation/landing/landing_screen.dart';
import 'providers/customer_provider.dart';
import 'core/cache/hive_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  await HiveCacheService.instance.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  bool _isHandlingDeepLink = false;

  @override
  void initState() {
    super.initState();
    _listenAuthEvents();
    _initDeepLinks();
  }

  void _listenAuthEvents() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/reset-password', (route) => false);
      } else if (data.event == AuthChangeEvent.signedIn) {
        // Clear stale data from previous user before loading new user's data
        ref.invalidate(customersProvider);
        ref.invalidate(totalUtangProvider);
        if (_isHandlingDeepLink) {
          _isHandlingDeepLink = false;
          _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/', (route) => false);
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        ref.invalidate(customersProvider);
        ref.invalidate(totalUtangProvider);
        HiveCacheService.instance.clearAll();
      }
    });
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('Deep link received: $uri');
    if (uri.scheme == 'io.supabase.utangtracker') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        try {
          _isHandlingDeepLink = true;
          await Supabase.instance.client.auth.exchangeCodeForSession(code);
          debugPrint('Session exchanged successfully!');
        } catch (e) {
          _isHandlingDeepLink = false;
          debugPrint('Deep link error: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Utang Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/subscription': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final isExpired = args == true;
          return SubscriptionScreen(isExpired: isExpired);
        },
        '/admin': (context) => const AdminHomeScreen(),
      },
    );
  }
}