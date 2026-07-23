import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';
import '../widgets/nfc_scan_dialog.dart';

class RegisterLearnerScreen extends StatefulWidget {
  const RegisterLearnerScreen({super.key});

  @override
  State<RegisterLearnerScreen> createState() => _RegisterLearnerScreenState();
}

class _RegisterLearnerScreenState extends State<RegisterLearnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cohortIdController = TextEditingController();

  String? _nfcUid;
  bool _fingerprintEnrolled = false;
  
  final BiometricService _biometricService = BiometricService();
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cohortIdController.dispose();
    super.dispose();
  }

  void _scanNfcCard() async {
    final uid = await NfcScanDialog.showScanDialog(context);
    if (uid != null) {
      setState(() {
        _nfcUid = uid;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("NFC Card Scanned: $uid"), backgroundColor: Colors.emerald),
        );
      }
    }
  }

  void _enrollFingerprint() async {
    try {
      final success = await _biometricService.authenticateLearner();
      if (success) {
        setState(() {
          _fingerprintEnrolled = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fingerprint enrolled successfully!"), backgroundColor: Colors.emerald),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _registerLearner() async {
    if (!_formKey.currentState!.validate()) return;

    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    
    // 1. Create learner
    final learner = await attendanceProvider.registerLearner(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      cohortId: _cohortIdController.text.trim(),
      nfcUid: _nfcUid,
    );

    if (learner != null) {
      // 2. If fingerprint enrolled is true, update the fingerprint flag on backend
      if (_fingerprintEnrolled) {
        try {
          await _apiService.patch(
            '/learners/${learner.learnerId}/fingerprint',
            data: {'fingerprint_enrolled': true},
          );
        } catch (_) {
          // Ignore fingerprint patch failures or log them
        }
      }

      // 3. Show Success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.emerald, size: 28),
                SizedBox(width: 10),
                Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Learner registered successfully!"),
                const SizedBox(height: 16),
                Text(
                  "SEG ID: ${learner.segId}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.emerald,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                Text("Name: ${learner.fullName}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dismiss dialog
                  Navigator.of(context).pop(); // navigate back
                },
                child: const Text("OK", style: TextStyle(color: Colors.emerald, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attendanceProvider.errorMessage ?? "Failed to register learner."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Learner"),
        backgroundColor: Colors.emerald,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "New Learner Enrollment",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.emerald),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please fill in details and enroll NFC/fingerprint credentials.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter the learner's full name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Field (Optional)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number (Optional)",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Cohort ID Field
              TextFormField(
                controller: _cohortIdController,
                decoration: InputDecoration(
                  labelText: "Cohort ID",
                  prefixIcon: const Icon(Icons.class_),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter the Cohort ID";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Credential Section Title
              const Text(
                "Verification Credentials",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 16),
              const SizedBox(height: 8),

              // NFC Scan row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("NFC Card UID", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _nfcUid ?? "Not scanned yet",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: _nfcUid != null ? Colors.emerald : Colors.grey,
                            fontWeight: _nfcUid != null ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _scanNfcCard,
                    icon: const Icon(Icons.nfc_rounded),
                    label: const Text("Scan NFC"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade50,
                      foregroundColor: Colors.teal,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Fingerprint Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Fingerprint Enrolled", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _fingerprintEnrolled ? "Enrolled" : "Not enrolled yet",
                          style: TextStyle(
                            color: _fingerprintEnrolled ? Colors.emerald : Colors.grey,
                            fontWeight: _fingerprintEnrolled ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _enrollFingerprint,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text("Enroll Fingerprint"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.emerald.shade50,
                      foregroundColor: Colors.emerald,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Register Button
              ElevatedButton(
                onPressed: attendanceProvider.isLoading ? null : _registerLearner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: attendanceProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("Register Learner", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
