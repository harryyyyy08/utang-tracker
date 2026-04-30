import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(),
            const _FeaturesSection(),
            const _HowToUseSection(),
            const _CtaSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blue background with curved bottom
        ClipPath(
          clipper: _BottomCurveClipper(),
          child: Container(
            width: double.infinity,
            color: const Color(0xFF1E88E5),
            padding: const EdgeInsets.only(
                top: 72, left: 24, right: 24, bottom: 64),
            child: Column(
              children: [
                const Icon(Icons.store, size: 72, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Utang Tracker',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Para sa iyong tindahan',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'I-manage ang utang ng iyong mga customers\nnang madali, mabilis, at organisado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ── Features ──────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  static const _features = [
    (
      icon: Icons.receipt_long,
      color: Color(0xFF1E88E5),
      title: 'Track ng Utang at Bayad',
      desc:
          'I-record ang bawat transaksyon — kung magkano ang utang at kung kailan at paano nagbayad ang customer.',
    ),
    (
      icon: Icons.people_alt,
      color: Color(0xFF43A047),
      title: 'Manage ng Customers',
      desc:
          'Lahat ng impormasyon ng iyong customers — pangalan, numero, credit limit, at kasaysayan ng utang — nasa iisang lugar.',
    ),
    (
      icon: Icons.bar_chart,
      color: Color(0xFF8E24AA),
      title: 'Dashboard at Reports',
      desc:
          'Tingnan ang kabuuang utang at monthly collections sa isang malinaw na dashboard at charts.',
    ),
    (
      icon: Icons.payment,
      color: Color(0xFF00ACC1),
      title: 'GCash, Cash, at iba pa',
      desc:
          'I-track kung paano nagbayad ang customers — Cash, GCash, PayMaya, Bank Transfer, at iba pa.',
    ),
    (
      icon: Icons.picture_as_pdf_outlined,
      color: Color(0xFFE53935),
      title: 'PDF Statement of Account',
      desc:
          'Gumawa ng PDF statement para sa bawat customer at i-share o i-print nang direkta mula sa app.',
    ),
    (
      icon: Icons.wifi_off,
      color: Color(0xFF546E7A),
      title: 'Gumagana Kahit Offline',
      desc:
          'Hindi ka mapipigilan ng masamang signal. Naka-cache ang data mo kaya maa-access mo ito kahit walang internet.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ano ang Utang Tracker?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lahat ng kailangan ng iyong tindahan.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ..._features.map((f) => _FeatureCard(
                icon: f.icon,
                color: f.color,
                title: f.title,
                desc: f.desc,
              )),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text(desc,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── How To Use ────────────────────────────────────────────────────────────────

class _HowToUseSection extends StatelessWidget {
  const _HowToUseSection();

  static const _steps = [
    (
      label: 'Gumawa ng account',
      detail: 'I-register ang iyong tindahan — libre at mabilis lang.',
    ),
    (
      label: 'Magdagdag ng customers',
      detail:
          'I-save ang pangalan at contact ng bawat customer na may utang sa iyo.',
    ),
    (
      label: 'I-record ang transaksyon',
      detail:
          'Mag-tap ng "Utang" o "Bayad" para mag-add ng bagong transaksyon — kasama na ang interest at due date.',
    ),
    (
      label: 'Subaybayan ang balanse',
      detail:
          'Makita agad kung sino ang may utang, magkano, at kung overdue na.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paano Gamitin?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          ..._steps.asMap().entries.map((e) => _StepRow(
                number: e.key + 1,
                label: e.value.label,
                detail: e.value.detail,
                isLast: e.key == _steps.length - 1,
              )),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String label;
  final String detail;
  final bool isLast;

  const _StepRow({
    required this.number,
    required this.label,
    required this.detail,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number + connector line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFBBDEFB),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 3),
                  Text(detail,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.45)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA ───────────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Magsimula — Gumawa ng Account',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E88E5),
                side: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Mayroon nang Account — Mag-login',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '✓ Libre ang 14 araw na trial  ·  ✓ Walang credit card na kailangan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
