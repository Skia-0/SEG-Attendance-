import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/nfc_service.dart';
import '../services/biometric_service.dart';
import '../models/learner.dart';

class LearnerDetailScreen extends StatefulWidget {
  final String learnerId;
  const LearnerDetailScreen({super.key, required this.learnerId});

  @override
  State<LearnerDetailScreen> createState() =>
      _LearnerDetailScreenState();
}

class _LearnerDetailScreenState extends State<LearnerDetailScreen> {
  final _api = ApiService();
  final _nfc = NfcService();
  final _bio = BiometricService();
  Learner? _learner;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getLearner(widget.learnerId);
      _learner = Learner.fromJson(res.data);
    } catch (_) {
      _learner = null;
    }
    setState(() => _loading = false);
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error
            ? Colors.red.shade700
            : const Color(0xFFFF6B00),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editName() async {
    final controller =
        TextEditingController(text: _learner?.fullName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || result.length < 3) return;

    try {
      await _api.updateLearner(
        learnerId: widget.learnerId,
        fullName: result,
      );
      _load();
      _snack('Name updated');
    } catch (_) {
      _snack('Failed to update', error: true);
    }
  }

  Future<void> _editPhone() async {
    final controller =
        TextEditingController(text: _learner?.phone ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Phone'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await _api.updateLearner(
        learnerId: widget.learnerId,
        phone: result,
      );
      _load();
      _snack('Phone updated');
    } catch (_) {
      _snack('Failed to update', error: true);
    }
  }

  Future<void> _rescanNfc() async {
    final available = await _nfc.isAvailable();
    if (!available) {
      _snack('NFC not available', error: true);
      return;
    }
    _snack('Hold NFC card to phone...');
    final uid = await _nfc.readUid(timeoutSeconds: 20);
    if (uid == null) {
      _snack('No card detected', error: true);
      return;
    }
    try {
      await _api.updateLearner(
        learnerId: widget.learnerId,
        nfcUid: uid,
      );
      _load();
      _snack('New card assigned: $uid');
    } catch (_) {
      _snack('Failed to update card', error: true);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Learner?'),
        content: Text(
          'This will permanently remove ${_learner?.fullName ?? "this learner"} '
          'and all their attendance records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteLearner(widget.learnerId);
      if (!mounted) return;
      Navigator.pop(context);
      _snack('Learner deleted');
    } catch (_) {
      _snack('Failed to delete', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('LEARNER'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B00),
              ),
            )
          : _learner == null
              ? const Center(child: Text('Learner not found'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: const Color(0xFF1A1A1A),
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          24,
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor:
                                  const Color(0xFFFF6B00),
                              child: Text(
                                _learner!.fullName
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _learner!.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B00),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                _learner!.segId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Tile(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        value: _learner!.fullName,
                        onEdit: _editName,
                      ),
                      _Tile(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: _learner!.phone?.isNotEmpty == true
                            ? _learner!.phone!
                            : 'Not set',
                        onEdit: _editPhone,
                      ),
                      _Tile(
                        icon: Icons.nfc,
                        label: 'NFC Card',
                        value: _learner!.nfcUid?.isNotEmpty == true
                            ? _learner!.nfcUid!
                            : 'No card assigned',
                        onEdit: _rescanNfc,
                        editLabel: 'Rescan',
                      ),
                      _Tile(
                        icon: Icons.fingerprint,
                        label: 'Fingerprint',
                        value: _learner!.fingerprintEnrolled
                            ? 'Enrolled'
                            : 'Not enrolled',
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final String editLabel;

  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
    this.editLabel = 'Edit',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF6B00), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              TextButton(
                onPressed: onEdit,
                child: Text(
                  editLabel,
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}