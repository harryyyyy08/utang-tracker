import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionScreen extends StatelessWidget {
  final bool isExpired;
  const SubscriptionScreen({super.key, this.isExpired = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      // ← Magpakita ng back button kapag hindi pa expired
      appBar: isExpired
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Icon(
                isExpired ? Icons.lock_outline : Icons.workspace_premium,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                isExpired
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
                isExpired
                    ? 'Mag-subscribe na para magpatuloy. Ang iyong data ay ligtas pa rin.'
                    : 'Mag-subscribe para sa walang limitasyong paggamit pagkatapos ng trial.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Pricing Card
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
                        style:
                        TextStyle(fontSize: 16, color: Colors.grey)),
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

              // Payment Instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paano mag-subscribe:',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    SizedBox(height: 8),
                    Text('1. Mag-GCash ng ₱99 sa:',
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 4),
                    Text('   📱 09203824776 CA*L H*Y C.',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('2. I-screenshot ang receipt',
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 4),
                    Text('3. Ipadala sa Facebook: \nhttps://www.facebook.com/system.out.println08',
                        style: TextStyle(color: Colors.white)),
                    SizedBox(height: 4),
                    Text('4. Ia-activate namin sa loob ng 24 hours',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout button — ipakita lang kapag expired
              if (isExpired)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Mag-logout'),
                  ),
                ),

              // Back button — ipakita lang kapag hindi pa expired
              if (!isExpired)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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