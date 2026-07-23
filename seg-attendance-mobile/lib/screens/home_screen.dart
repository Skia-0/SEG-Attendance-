import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'register_learner_screen.dart';
import 'cohort_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("SEG Hub Attendance"),
        backgroundColor: Colors.emerald,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              "Welcome, ${authProvider.coordinatorName ?? 'Coordinator'}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.emerald,
              ),
              textAlign: Center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Manage learners and verify session attendance",
              textAlign: Center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),

            // Register Learner Card
            _buildMenuCard(
              context: context,
              title: "Register Learner",
              subtitle: "Enroll a new learner, scan NFC & register fingerprint",
              icon: Icons.person_add_rounded,
              color: Colors.emerald,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterLearnerScreen()),
                );
              },
            ),
            const SizedBox(height: 20),

            // Manage Cohort Card
            _buildMenuCard(
              context: context,
              title: "Manage Cohort",
              subtitle: "Start sessions & open check-in/check-out",
              icon: Icons.groups_rounded,
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CohortScreen()),
                );
              },
            ),
            const SizedBox(height: 20),

            // Summary Card
            _buildMenuCard(
              context: context,
              title: "Cohort Summary",
              subtitle: "View attendance percent & certification threshold",
              icon: Icons.assignment_turned_in_rounded,
              color: Colors.blueGrey,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SummaryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
