import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegistered = false;
  bool? _referralCodeValid; // null = empty, true = valid, false = invalid
  bool _isCheckingCode = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _referralCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onReferralCodeChanged(String value) {
    _debounce?.cancel();
    final code = value.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() { _referralCodeValid = null; _isCheckingCode = false; });
      return;
    }
    setState(() => _isCheckingCode = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final result = await Supabase.instance.client
            .rpc('validate_referral_code', params: {'code': code});
        if (mounted) setState(() { _referralCodeValid = result == true; _isCheckingCode = false; });
      } catch (_) {
        if (mounted) setState(() { _referralCodeValid = null; _isCheckingCode = false; });
      }
    });
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _storeNameController.text.isEmpty ||
        _ownerNameController.text.isEmpty) {
      _showError('Punan ang lahat ng required fields');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Ang password ay dapat hindi bababa sa 6 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Hindi magkatugma ang mga password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: 'io.supabase.utangtracker://login-callback',
        data: {
          'store_name': _storeNameController.text.trim(),
          'owner_name': _ownerNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'referral_code': _referralCodeController.text.trim().toUpperCase(),
        },
      );

      debugPrint('Register response: ${response.user?.id}');
      debugPrint('Register session: ${response.session}');

      if (!mounted) return;

      if (response.user != null) {
        setState(() => _isRegistered = true);
      } else {
        _showError('May error sa pag-register. Subukan ulit.');
      }
    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.message}');
      if (e.message.contains('User already registered')) {
        _showError('May account na ang email na ito. Mag-login na lang.');
      } else {
        _showError(e.message);
      }
    } catch (e) {
      debugPrint('Unknown error: $e');
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // "Check your email" screen
  Widget _buildEmailSentScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'I-check ang iyong Email!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Nagpadala kami ng confirmation link sa:\n${_emailController.text}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'I-click ang link sa email para ma-activate ang iyong account.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Pumunta sa Login',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  // Resend confirmation email
                  try {
                    await Supabase.instance.client.auth.resend(
                      type: OtpType.signup,
                      email: _emailController.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Na-resend ang confirmation email!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) _showError('Hindi ma-resend. Subukan ulit.');
                  }
                },
                child: const Text(
                  'Hindi natanggap? I-resend',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kung naka-register na, ipakita ang email sent screen
    if (_isRegistered) return _buildEmailSentScreen();

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
              const SizedBox(height: 16),
              const Icon(Icons.store, size: 50, color: Color(0xFF1E88E5)),
              const SizedBox(height: 16),
              const Text('Gumawa ng Account',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('I-setup ang iyong tindahan',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Pangalan ng Tindahan *',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Pangalan mo *',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password * (min. 6 characters)',
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
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() =>
                    _obscureConfirmPassword =
                    !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _referralCodeController,
                textCapitalization: TextCapitalization.characters,
                onChanged: _onReferralCodeChanged,
                decoration: InputDecoration(
                  labelText: 'Referral Code (opsyonal)',
                  prefixIcon: const Icon(Icons.card_giftcard_outlined),
                  helperText: 'Kung may nagbigay sa iyo ng code, ilagay ito dito.',
                  suffixIcon: _isCheckingCode
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _referralCodeValid == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : _referralCodeValid == false
                              ? const Icon(Icons.cancel, color: Colors.red)
                              : null,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Mag-register'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('May account na? '),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, '/login'),
                      child: const Text('Mag-login',
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