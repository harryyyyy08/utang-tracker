import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isExpired;
  const SubscriptionScreen({super.key, this.isExpired = false});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _txController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _txController.dispose();
    super.dispose();
  }

  String get _paymentCode {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return 'UT-${userId.substring(0, 6).toUpperCase()}';
  }

  Future<void> _submit() async {
    final txId = _txController.text.trim();
    if (txId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ilagay ang GCash Transaction ID.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // Block if there's already a pending payment
      final pending = await supabase
          .from('payments')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'pending');
      if ((pending as List).isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'May pending na bayad ka pa. Hintayin muna ang approval bago mag-submit ulit.'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _submitted = true);
        }
        return;
      }

      // Block if submitted 3+ times today already
      final todayStart = DateTime.now().toUtc().copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      final todaySubmissions = await supabase
          .from('payments')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', todayStart.toIso8601String());
      if ((todaySubmissions as List).length >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Naabot na ang limit ng submissions ngayon. Subukan ulit bukas.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await supabase.from('payments').insert({
        'user_id': userId,
        'payment_code': _paymentCode,
        'gcash_transaction_id': txId,
        'amount': 9900,
        'status': 'pending',
      });

      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hindi naisumite. Subukan ulit. ($e)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('profiles')
          .select('subscription_status')
          .eq('id', userId)
          .single();

      if (data['subscription_status'] == 'active' && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Hindi pa na-approve. Abangan ang confirmation.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      appBar: widget.isExpired
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Mag-subscribe',
                  style: TextStyle(color: Colors.white)),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Icon(
                widget.isExpired ? Icons.lock_outline : Icons.workspace_premium,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                widget.isExpired
                    ? 'Nag-expire na ang iyong Trial'
                    : 'I-upgrade ang iyong Account',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.isExpired
                    ? 'Mag-subscribe na para magpatuloy. Ang iyong data ay ligtas pa rin.'
                    : 'Mag-subscribe para sa walang limitasyong paggamit pagkatapos ng trial.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Pricing card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('Monthly Plan',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text('₱99',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        )),
                    const Text('per buwan',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildFeature('✅ Unlimited customers'),
                    _buildFeature('✅ Unlimited transactions'),
                    _buildFeature('✅ Dashboard at reports'),
                    _buildFeature('✅ Secure cloud backup'),
                    _buildFeature('✅ Hindi mabubura ang data'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment section
              _submitted ? _buildSubmittedCard() : _buildPaymentForm(),

              const SizedBox(height: 20),

              if (widget.isExpired)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                      Supabase.instance.client.auth.signOut();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Mag-logout'),
                  ),
                ),

              if (!widget.isExpired)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Bumalik sa App'),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paano mag-subscribe:',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Ia-approve sa loob ng 1 oras · 8AM – 10PM',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('1. Mag-GCash ng ₱99 sa:',
              style: TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          const Text(
            '   📱 09203824776  CA*L H*Y C.',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(24),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'GCash QR Code',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '09203824776  CA*L H*Y C.',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Image.asset(
                              'assets/images/harry_gcash.jpg',
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'I-scan gamit ang GCash app',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/harry_gcash.jpg',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('I-scan ang QR',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1E88E5))),
                        SizedBox(height: 2),
                        Text('Pindutin para palakihin',
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.zoom_in,
                        color: Color(0xFF1E88E5), size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Payment code
          Row(
            children: [
              const Expanded(
                child: Text(
                  '2. I-type ang code na ito\n   bilang note/message sa GCash:',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _paymentCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-copy ang payment code!')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _paymentCode,
                    style: const TextStyle(
                      color: Color(0xFF1E88E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, size: 16, color: Color(0xFF1E88E5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Transaction ID input
          const Text(
            '3. Ilagay ang GCash Transaction ID\n   (makikita sa GCash receipt):',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _txController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Hal. 1234567890123',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1E88E5)),
                    )
                  : const Text(
                      'Isumite ang Bayad',
                      style: TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white38),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Naisumite na ang iyong bayad!',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ia-approve ito sa loob ng ilang minuto. I-tap ang button sa ibaba kapag may natanggap kang confirmation.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.85), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _refreshStatus,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1E88E5)),
                    )
                  : const Icon(Icons.refresh, color: Color(0xFF1E88E5)),
              label: const Text(
                'I-check ang Status',
                style: TextStyle(
                    color: Color(0xFF1E88E5), fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
