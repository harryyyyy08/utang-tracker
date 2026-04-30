import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/error_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Rate limiting: max 3 requests per 10 minutes per email
  static const int _maxRequests = 3;
  static const Duration _window = Duration(minutes: 10);
  final Map<String, List<DateTime>> _resetRequestLog = {};

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Punan ang lahat ng fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        // Bumalik sa splash para ma-check ang subscription
        Navigator.pushNamedAndRemoveUntil(
            context, '/', (route) => false);
      }
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) {
        _showError('Hindi pa na-confirm ang email mo. I-check ang iyong inbox.');
      } else if (e.message.contains('Invalid login credentials')) {
        _showError('Mali ang email o password. Subukan ulit.');
      } else {
        _showError(e.message);
      }
    } catch (e) {
      _showError(friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isRateLimited(String email) {
    final now = DateTime.now();
    final requests = _resetRequestLog[email] ?? [];
    // Remove entries outside the window
    requests.removeWhere((t) => now.difference(t) > _window);
    _resetRequestLog[email] = requests;
    return requests.length >= _maxRequests;
  }

  void _recordRequest(String email) {
    _resetRequestLog[email] = [...(_resetRequestLog[email] ?? []), DateTime.now()];
  }

  Future<bool> _emailExistsInApp(String email) async {
    final result = await Supabase.instance.client
        .rpc('check_email_exists', params: {'email_input': email});
    return result == true;
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController =
    TextEditingController(text: _emailController.text);
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Ilagay ang iyong email para makatanggap ng reset link.'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;

                      if (_isRateLimited(email)) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showError(
                              'Maraming beses nang na-request. Subukan ulit pagkatapos ng 10 minuto.');
                        }
                        return;
                      }

                      // Record attempt before any async check so every try counts
                      _recordRequest(email);
                      setDialogState(() => isSending = true);

                      try {
                        final exists = await _emailExistsInApp(email);
                        if (!exists) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showError(
                                'Walang account na nagrehistro sa email na \'$email\'.');
                          }
                          return;
                        }

                        await Supabase.instance.client.auth.resetPasswordForEmail(
                          email,
                          redirectTo:
                              'io.supabase.utangtracker://login-callback?type=recovery',
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Na-send ang reset link sa iyong email!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } on AuthException catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (e.message.toLowerCase().contains('rate limit') ||
                              e.message.toLowerCase().contains('email rate')) {
                            _showError(
                                'Sobrang daming request. Subukan ulit mamaya.');
                          } else {
                            _showError('Hindi ma-send: ${e.message}');
                          }
                        }
                      } catch (_) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showError(
                              'Walang koneksyon o may error sa server. I-check ang iyong internet.');
                        }
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('I-send ang Reset Link'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Bumalik',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/landing', (route) => false),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.store, size: 50, color: Color(0xFF1E88E5)),
              const SizedBox(height: 16),
              const Text('Magandang araw!',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('Mag-login sa iyong account',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showForgotPasswordDialog,
                    child: const Text(
                      'Nakalimutan ang password?',
                      style: TextStyle(
                          color: Color(0xFF1E88E5), fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Mag-login'),
              ),
              const SizedBox(height: 16),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Wala pang account? '),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, '/register'),
                      child: const Text('Mag-register',
                          style: TextStyle(
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}