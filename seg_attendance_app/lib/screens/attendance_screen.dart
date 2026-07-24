import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_record.dart';
import '../services/nfc_service.dart';
import '../services/biometric_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String cohortName;

  const AttendanceScreen({
    super.key,
    required this.sessionId,
    required this.cohortName,
  });

  @override
  State<AttendanceScreen> createState() =>
      _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _nfc = NfcService();
  final _bio = BiometricService();
  bool _nfcListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<AttendanceProvider>();
      await prov.loadSession(widget.sessionId);
      prov.startPolling();
    });
  }

  @override
  void dispose() {
    context.read<AttendanceProvider>().stopPolling();
    _nfc.stop();
    super.dispose();
  }

  Future<void> _startNfcListening() async {
    if (_nfcListening) return;

    final available = await _nfc.isAvailable();
    if (!available) return;

    _nfcListening = true;

    await _nfc.startBackgroundScan((uid) async {
      await _handleNfcTap(uid);
    });
  }

  Future<void> _stopNfcListening() async {
    _nfcListening = false;
    await _nfc.stop();
  }

  Future<void> _handleNfcTap(String uid) async {
    final prov = context.read<AttendanceProvider>();
    if (prov.session == null) return;

    final learner = prov.records.firstWhere(
      (r) => r.segId != null && _findByNfc(r, uid),
      orElse: () => AttendanceRecord(
        recordId: '',
        sessionId: '',
        learnerId: '',
        verificationMethod: 'nfc',
      ),
    );

    if (learner.learnerId.isEmpty) {
      _showSnack('Unknown card. Register this card first.',
          isError: true);
      await Future.delayed(const Duration(seconds: 1));
      _startNfcListening();
      return;
    }

    await _doCheckAction(learner, 'nfc');

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted &&
        (prov.session?.checkinOpen == true ||
            prov.session?.checkoutOpen == true)) {
      _startNfcListening();
    }
  }

  bool _findByNfc(AttendanceRecord r, String uid) {
    return false;
  }

  Future<void> _doCheckAction(
      AttendanceRecord learner, String method) async {
    final prov = context.read<AttendanceProvider>();
    if (prov.session == null) return;

    String? error;
    String actionLabel = '';

    if (prov.session!.checkinOpen) {
      error = await prov.checkIn(
        learnerId: learner.learnerId,
        method: method,
      );
      actionLabel = 'Checked in';
    } else if (prov.session!.checkoutOpen) {
      error = await prov.checkOut(
        learnerId: learner.learnerId,
        method: method,
      );
      actionLabel = 'Checked out';
    } else {
      _showSnack('Open check-in or check-out first',
          isError: true);
      return;
    }

    if (!mounted) return;

    if (error == null) {
      _showSnack(
          '$actionLabel: ${learner.fullName ?? "Learner"}');
    } else {
      _showSnack(error, isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFFFF6B00),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openCheckin() async {
    final ok = await context
        .read<AttendanceProvider>()
        .openCheckin();
    if (ok) {
      _showSnack('Check-in is now open');
      _startNfcListening();
    } else {
      _showSnack('Failed to open check-in', isError: true);
    }
  }

  Future<void> _openCheckout() async {
    final ok = await context
        .read<AttendanceProvider>()
        .openCheckout();
    if (ok) {
      _showSnack('Check-out is now open');
      _startNfcListening();
    } else {
      _showSnack('Failed to open check-out', isError: true);
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text(
          'No more check-ins or check-outs will be '
          'accepted after this.',
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
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _stopNfcListening();
    final ok =
        await context.read<AttendanceProvider>().endSession();
    if (ok && mounted) {
      _showSnack('Session ended');
      Navigator.pop(context);
    }
  }

  Future<void> _openFingerprintPicker() async {
    final prov = context.read<AttendanceProvider>();
    if (prov.session == null) return;

    if (!prov.session!.checkinOpen &&
        !prov.session!.checkoutOpen) {
      _showSnack('Open check-in or check-out first',
          isError: true);
      return;
    }

    await _stopNfcListening();

    final pending = prov.session!.checkinOpen
        ? prov.records.where((r) => !r.hasCheckedIn).toList()
        : prov.records
            .where(
                (r) => r.hasCheckedIn && !r.hasCheckedOut)
            .toList();

    if (pending.isEmpty) {
      _showSnack('No pending learners');
      _startNfcListening();
      return;
    }

    final selected = await showModalBottomSheet<AttendanceRecord>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => _LearnerPickerSheet(learners: pending),
    );

    if (selected == null) {
      _startNfcListening();
      return;
    }

    final error = await _bio.authenticate(
      reason:
          'Place ${selected.fullName ?? "learner"}\'s finger on sensor',
    );

    if (!mounted) return;

    if (error != null) {
      _showSnack(error, isError: true);
      _startNfcListening();
      return;
    }

    await _doCheckAction(selected, 'fingerprint');
    _startNfcListening();
  }

  void _showNfcInfo() {
    final prov = context.read<AttendanceProvider>();
    if (prov.session == null) return;

    if (!prov.session!.checkinOpen &&
        !prov.session!.checkoutOpen) {
      _showSnack('Open check-in or check-out first',
          isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.nfc,
                color: Color(0xFFFF6B00),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'NFC Auto-Scan Active',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'NFC scanning runs automatically in the '
              'background while check-in or check-out is open.\n\n'
              'Ask the learner to tap their card on the '
              'back of the phone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AttendanceProvider>();
    final session = prov.session;

    if (prov.loading || session == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B00),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SESSION'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await _stopNfcListening();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          _buildHeader(prov),
          _buildControls(prov),
          _buildStats(prov),
          const Divider(height: 1),
          Expanded(
            child: _buildLearnerList(prov),
          ),
        ],
      ),
      floatingActionButton: session.isEnded
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'nfc',
                  onPressed: _showNfcInfo,
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.nfc),
                  label: const Text(
                    'NFC',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'fingerprint',
                  onPressed: _openFingerprintPicker,
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text(
                    'Fingerprint',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(AttendanceProvider prov) {
    final s = prov.session!;
    String mode;
    Color modeColor;

    if (s.isEnded) {
      mode = 'ENDED';
      modeColor = Colors.grey.shade700;
    } else if (s.checkinOpen) {
      mode = 'CHECK-IN OPEN';
      modeColor = const Color(0xFFFF6B00);
    } else if (s.checkoutOpen) {
      mode = 'CHECK-OUT OPEN';
      modeColor = const Color(0xFFFF6B00);
    } else {
      mode = 'IDLE';
      modeColor = Colors.grey.shade600;
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.cohortName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: modeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  mode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AttendanceProvider prov) {
    final s = prov.session!;
    if (s.isEnded) {
      return Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Session has ended',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ControlButton(
                  label: 'Check-In',
                  icon: Icons.login,
                  active: s.checkinOpen,
                  onTap: _openCheckin,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ControlButton(
                  label: 'Check-Out',
                  icon: Icons.logout,
                  active: s.checkoutOpen,
                  onTap: _openCheckout,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _endSession,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('End Session'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade700),
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AttendanceProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _StatBox(
            label: 'Total',
            value: '${prov.totalLearners}',
            color: const Color(0xFF1A1A1A),
          ),
          const SizedBox(width: 8),
          _StatBox(
            label: 'Checked In',
            value: '${prov.checkedInCount}',
            color: const Color(0xFFFF6B00),
          ),
          const SizedBox(width: 8),
          _StatBox(
            label: 'Complete',
            value: '${prov.completeCount}',
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildLearnerList(AttendanceProvider prov) {
    if (prov.records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No learners registered in this cohort',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      itemCount: prov.records.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 8),
      itemBuilder: (context, i) => _LearnerRow(
        record: prov.records[i],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFFF6B00) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? const Color(0xFFFF6B00)
                  : const Color(0xFFDDDDDD),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: active
                    ? Colors.white
                    : const Color(0xFF1A1A1A),
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                active ? 'OPEN' : label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: active
                      ? Colors.white
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnerRow extends StatelessWidget {
  final AttendanceRecord record;
  const _LearnerRow({required this.record});

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    String status;
    Color color;
    IconData icon;

    if (record.isComplete) {
      status = 'COMPLETE';
      color = Colors.green.shade700;
      icon = Icons.check_circle;
    } else if (record.hasCheckedIn) {
      status = 'CHECKED IN';
      color = const Color(0xFFFF6B00);
      icon = Icons.login;
    } else {
      status = 'PENDING';
      color = Colors.grey.shade500;
      icon = Icons.radio_button_unchecked;
    }

    final checkInTime = _formatTime(record.checkedInAt);
    final checkOutTime = _formatTime(record.checkedOutAt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.fullName ?? 'Learner',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.segId ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (record.hasCheckedIn) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  _TimeChip(
                    label: 'IN',
                    time: checkInTime,
                    color: const Color(0xFFFF6B00),
                    method: record.verificationMethod,
                    show: true,
                  ),
                  const SizedBox(width: 12),
                  _TimeChip(
                    label: 'OUT',
                    time: checkOutTime,
                    color: Colors.green.shade700,
                    method: record.verificationMethod,
                    show: record.hasCheckedOut,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  final String method;
  final bool show;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.color,
    required this.method,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '—:—',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontFamily: 'monospace',
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          time,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          method == 'fingerprint'
              ? Icons.fingerprint
              : Icons.nfc,
          size: 10,
          color: Colors.grey.shade500,
        ),
      ],
    );
  }
}

class _LearnerPickerSheet extends StatelessWidget {
  final List<AttendanceRecord> learners;
  const _LearnerPickerSheet({required this.learners});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scroll) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  color: Color(0xFFFF6B00),
                ),
                SizedBox(width: 8),
                Text(
                  'Select Learner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: learners.length,
              itemBuilder: (_, i) {
                final l = learners[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        const Color(0xFFFFF3E0),
                    child: Text(
                      (l.fullName ?? '?')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(l.fullName ?? 'Learner'),
                  subtitle: Text(l.segId ?? ''),
                  onTap: () => Navigator.pop(context, l),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}