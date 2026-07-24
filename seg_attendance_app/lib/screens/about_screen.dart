import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ABOUT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/seg_app.png',
                width: 200,
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              const Text(
                'SEG Attendance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Hub Attendance Verification System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A dual-method biometric and NFC-based '
                      'attendance system built for Social Enterprise Ghana '
                      'to replace paper-based logbooks across all hubs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF444444),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _InfoRow(
                icon: Icons.fingerprint,
                text: 'Biometric fingerprint verification',
              ),
              const _InfoRow(
                icon: Icons.nfc,
                text: 'NFC card scanning',
              ),
              const _InfoRow(
                icon: Icons.verified_outlined,
                text: 'Automated certification tracking',
              ),
              const _InfoRow(
                icon: Icons.cloud_upload_outlined,
                text: 'Central reports repository',
              ),
              const SizedBox(height: 40),
              const Text(
                '© 2026 Social Enterprise Ghana',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Internal use only',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFAAAAAA),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B00), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF444444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}