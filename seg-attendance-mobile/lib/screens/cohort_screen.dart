import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import 'attendance_screen.dart';

class CohortScreen extends StatefulWidget {
  const CohortScreen({super.key});

  @override
  State<CohortScreen> createState() => _CohortScreenState();
}

class _CohortScreenState extends State<CohortScreen> {
  final _cohortIdController = TextEditingController();
  final _sessionTitleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cohortIdController.dispose();
    _sessionTitleController.dispose();
    super.dispose();
  }

  void _loadCohort() async {
    final cohortId = _cohortIdController.text.trim();
    if (cohortId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Cohort ID")),
      );
      return;
    }

    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final success = await sessionProvider.loadCohort(cohortId);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sessionProvider.errorMessage ?? "Failed to load cohort."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startSession() async {
    if (!_formKey.currentState!.validate()) return;

    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final cohort = sessionProvider.currentCohort;
    if (cohort == null) return;

    final success = await sessionProvider.startSession(
      cohort.cohortId,
      _sessionTitleController.text.trim(),
    );

    if (mounted) {
      if (success && sessionProvider.currentSession != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AttendanceScreen(
              sessionId: sessionProvider.currentSession!.sessionId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sessionProvider.errorMessage ?? "Failed to start session."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final cohort = sessionProvider.currentCohort;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cohort & Sessions"),
        backgroundColor: Colors.emerald,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Load Cohort Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.emerald),
            ),
            const SizedBox(height: 16),
            
            // Cohort ID Input Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cohortIdController,
                    decoration: InputDecoration(
                      labelText: "Cohort ID",
                      prefixIcon: const Icon(Icons.class_),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: sessionProvider.isLoading ? null : _loadCohort,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: sessionProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Load"),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Display Cohort Information
            if (cohort != null) ...[
              Card(
                color: Colors.emerald.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cohort.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.emerald),
                      ),
                      const Divider(height: 24, color: Colors.emerald),
                      _buildInfoRow(Icons.group, "Registered Learners: ${cohort.learnerCount ?? 0}"),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.rule, "Attendance Threshold: ${cohort.minAttendancePercent}%"),
                      if (cohort.startDate != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.calendar_today, "Timeline: ${cohort.startDate} to ${cohort.endDate ?? 'Present'}"),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Form to Start Session
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Start Session",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.emerald),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sessionTitleController,
                      decoration: InputDecoration(
                        labelText: "Session Title",
                        prefixIcon: const Icon(Icons.title_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter a session title";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: sessionProvider.isLoading ? null : _startSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Start Session", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 48),
              const Icon(Icons.class_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Please enter and load a valid Cohort ID to view options and start sessions.",
                textAlign: Center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.emerald.shade700, size: 20),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
