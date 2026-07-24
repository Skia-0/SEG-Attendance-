import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/nfc_service.dart';
import '../services/biometric_service.dart';

class RegisterLearnerScreen extends StatefulWidget {
  final String cohortId;
  final String cohortName;

  const RegisterLearnerScreen({
    super.key,
    required this.cohortId,
    required this.cohortName,
  });

  @override
  State<RegisterLearnerScreen> createState() =>
      _RegisterLearnerScreenState();
}

class _RegisterLearnerScreenState
    extends State<RegisterLearnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _api = ApiService();
  final _nfc = NfcService();
  final _bio = BiometricService();

  String? _nfcUid;
  bool _fingerprintEnrolled = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nfc.stop();
    super.dispose();
  }

  Future<void> _scanNfc() async {
    final available = await _nfc.isAvailable();
    if (!available && mounted) {
      _showError('NFC not available on this device');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NfcScanDialog(
        onCancel: () async {
          await _nfc.stop();
          if (mounted) Navigator.pop(context);
        },
      ),
    );

    final uid = await _nfc.readUid(timeoutSeconds: 30);

    if (!mounted) return;
    Navigator.pop(context);

    if (uid == null) {
      _showError('No card detected. Try again.');
      return;
    }

    setState(() => _nfcUid = uid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Card scanned: $uid'),
        backgroundColor: const Color(0xFFFF6B00),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _enrollFingerprint() async {
  final available = await _bio.isAvailable();
  if (!available && mounted) {
    _showError(
      'Biometrics not available on this phone. '
      'Please enroll a fingerprint in Settings first.',
    );
    return;
  }

  final error = await _bio.authenticate(
    reason: 'Place learner\'s finger on sensor to enroll',
  );

  if (!mounted) return;

  if (error == null) {
    setState(() => _fingerprintEnrolled = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fingerprint enrolled'),
        backgroundColor: Color(0xFFFF6B00),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else {
    _showError(error);
  }
}
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nfcUid == null && !_fingerprintEnrolled) {
      _showError(
        'Please register either an NFC card or fingerprint',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await _api.registerLearner(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        cohortId: widget.cohortId,
        nfcUid: _nfcUid,
      );

      final learnerId = response.data['learner_id'].toString();
      final segId = response.data['seg_id']?.toString() ?? '';

      // If fingerprint was enrolled, update backend
      if (_fingerprintEnrolled) {
        await _api.updateFingerprintStatus(learnerId);
      }

      if (!mounted) return;
      setState(() => _loading = false);
      _showSuccess(segId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Registration failed. Try again.');
    }
  }

  void _showSuccess(String segId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFFFF6B00),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Learner Registered!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFDDDDDD),
                ),
              ),
              child: Text(
                segId,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B00),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'SEG ID assigned',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetForm();
                    },
                    child: const Text('Add Another'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    setState(() {
      _nfcUid = null;
      _fingerprintEnrolled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ADD LEARNER'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cohortName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFF6B00),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Register New Learner',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter learner name';
                    }
                    if (v.trim().length < 3) {
                      return 'Name too short';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Verification Methods',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF666666),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Register at least one method',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 12),

                _MethodTile(
                  icon: Icons.nfc_outlined,
                  title: 'NFC Card',
                  subtitle: _nfcUid == null
                      ? 'Tap to scan card'
                      : 'UID: $_nfcUid',
                  done: _nfcUid != null,
                  onTap: _scanNfc,
                ),

                const SizedBox(height: 10),

                _MethodTile(
                  icon: Icons.fingerprint,
                  title: 'Fingerprint',
                  subtitle: _fingerprintEnrolled
                      ? 'Enrolled successfully'
                      : 'Tap to enroll',
                  done: _fingerprintEnrolled,
                  onTap: _enrollFingerprint,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Register Learner'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: done
                  ? const Color(0xFFFF6B00)
                  : const Color(0xFFDDDDDD),
              width: done ? 1.5 : 1,
            ),
            color: done
                ? const Color(0xFFFFF3E0)
                : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFFFF6B00)
                      : const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color:
                      done ? Colors.white : const Color(0xFFFF6B00),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: done
                            ? const Color(0xFFFF6B00)
                            : const Color(0xFF888888),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (done)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFFFF6B00),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NfcScanDialog extends StatelessWidget {
  final VoidCallback onCancel;
  const _NfcScanDialog({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nfc_rounded,
                color: Color(0xFFFF6B00),
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to Scan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hold the NFC card near the back of the phone',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Color(0xFFFF6B00),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}