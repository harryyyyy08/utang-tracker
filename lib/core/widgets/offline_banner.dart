import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF323232),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 14),
          SizedBox(width: 6),
          Text(
            'Offline — pinapakita ang naka-save na data',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
