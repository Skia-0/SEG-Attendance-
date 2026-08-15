import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('PRIVACY POLICY'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'SEG Attendance System\nPrivacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Last updated: August 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _section(
              'What Data We Collect',
              'When you use the SEG Attendance System, we collect:\n\n'
              '• Coordinator Information: Full name, work email address, '
              'phone number (optional, for account recovery).\n\n'
              '• Learner Information: Full name, phone number (optional), '
              'SEG ID (auto-generated), NFC card UID, fingerprint '
              'enrollment status.\n\n'
              '• Attendance Records: Check-in and check-out timestamps, '
              'verification method used (fingerprint, NFC, or manual), '
              'manual override reasons.\n\n'
              '• Session Data: Session titles, start/end times, '
              'cohort information.\n\n'
              '• Usage Data: Audit logs of coordinator actions, '
              'IP addresses for security monitoring.',
            ),

            _section(
              'Fingerprint Data',
              'IMPORTANT: Fingerprint data is processed entirely on '
              'the coordinator\'s phone using Android\'s secure hardware '
              'enclave. Fingerprint templates are NEVER transmitted to '
              'our servers or stored in our database.\n\n'
              'We only record whether a fingerprint verification was '
              'successful (true/false) and log it as the verification '
              'method. The actual biometric data remains on the device.',
            ),

            _section(
              'NFC Card Data',
              'NFC cards contain only a hardware-level unique identifier '
              '(UID). This is a number like "04:A3:B7:2C" — not personal '
              'data. We map this UID to a learner\'s record so attendance '
              'can be recorded when the card is tapped.\n\n'
              'No personal data is stored on the NFC card itself.',
            ),

            _section(
              'How We Use Your Data',
              '• Recording and verifying attendance at SEG hub sessions\n'
              '• Generating attendance reports for certification decisions\n'
              '• Monitoring system security (failed logins, manual overrides)\n'
              '• Improving the attendance verification process\n'
              '• Communicating account-related information (OTP codes, '
              'password resets)',
            ),

            _section(
              'Who Can Access Your Data',
              '• Hub Coordinators: Can only see data for their own hub\'s '
              'cohorts, learners, and sessions.\n\n'
              '• SEG Central Admins: Can view data across all hubs for '
              'oversight, reporting, and certification decisions.\n\n'
              '• No Third Parties: We do not sell, share, or provide '
              'your data to any external organization.',
            ),

            _section(
              'Data Storage & Security',
              '• Data is stored in a secure PostgreSQL database hosted '
              'on Neon (cloud provider) with encryption at rest.\n\n'
              '• All communications between the app and server use HTTPS '
              '(TLS encryption).\n\n'
              '• Access tokens expire after 7 days. Refresh tokens expire '
              'after 30 days.\n\n'
              '• Accounts are locked after 5 failed login attempts.\n\n'
              '• All sensitive actions are recorded in an audit log.',
            ),

            _section(
              'Data Retention',
              '• Attendance records are kept for the duration of the '
              'cohort plus 2 years after cohort completion.\n\n'
              '• Audit logs are retained for 1 year.\n\n'
              '• NFC card mappings are cleared at the end of each cohort '
              'and cards are returned to the pool for reuse.\n\n'
              '• Coordinator accounts remain active until deactivated '
              'by an administrator.',
            ),

            _section(
              'Your Rights',
              'Under the Ghana Data Protection Act 2012, you have the '
              'right to:\n\n'
              '• Access: Request a copy of your personal data.\n\n'
              '• Correction: Request correction of inaccurate data.\n\n'
              '• Deletion: Request deletion of your data (subject to '
              'legal retention requirements).\n\n'
              '• Complaint: Lodge a complaint with the Data Protection '
              'Commission of Ghana.\n\n'
              'To exercise these rights, contact your hub coordinator '
              'or SEG central office.',
            ),

            _section(
              'Contact',
              'Social Enterprise Ghana\n'
              'Data Protection Officer\n'
              'Email: privacy@seghana.net\n\n'
              'For technical support:\n'
              'Email: support@seghana.net',
            ),

            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF6B00).withOpacity(0.3),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFFFF6B00),
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This system is for internal use only by '
                    'Social Enterprise Ghana and its authorized '
                    'hub coordinators.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B00),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF444444),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}