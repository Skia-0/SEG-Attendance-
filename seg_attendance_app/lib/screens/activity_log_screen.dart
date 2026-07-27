import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() =>
      _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _api = ApiService();
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getAuditLog();
      _logs = res.data as List<dynamic>;
    } catch (_) {
      _logs = [];
    }
    setState(() => _loading = false);
  }

  String _formatTime(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  ({String label, IconData icon, Color color}) _describeAction(
      String action) {
    switch (action) {
      case 'coordinator.registered':
        return (
          label: 'Registered account',
          icon: Icons.person_add,
          color: const Color(0xFFFF6B00),
        );
      case 'coordinator.login':
        return (
          label: 'Signed in',
          icon: Icons.login,
          color: Colors.blue.shade700,
        );
      case 'coordinator.profile_updated':
        return (
          label: 'Updated profile',
          icon: Icons.person_outline,
          color: Colors.blue.shade700,
        );
      case 'coordinator.password_changed':
        return (
          label: 'Changed password',
          icon: Icons.lock_reset,
          color: Colors.orange.shade700,
        );
      case 'cohort.created':
        return (
          label: 'Created cohort',
          icon: Icons.groups_outlined,
          color: const Color(0xFFFF6B00),
        );
      case 'cohort.deleted':
        return (
          label: 'Deleted cohort',
          icon: Icons.delete_outline,
          color: Colors.red.shade700,
        );
      case 'session.created':
        return (
          label: 'Started session',
          icon: Icons.play_circle_outline,
          color: const Color(0xFFFF6B00),
        );
      case 'session.checkin_opened':
        return (
          label: 'Opened check-in',
          icon: Icons.login,
          color: Colors.green.shade700,
        );
      case 'session.checkin_closed':
        return (
          label: 'Closed check-in',
          icon: Icons.logout,
          color: Colors.grey.shade600,
        );
      case 'session.checkout_opened':
        return (
          label: 'Opened check-out',
          icon: Icons.logout,
          color: Colors.green.shade700,
        );
      case 'session.checkout_closed':
        return (
          label: 'Closed check-out',
          icon: Icons.close,
          color: Colors.grey.shade600,
        );
      case 'session.ended':
        return (
          label: 'Ended session',
          icon: Icons.stop_circle_outlined,
          color: Colors.red.shade700,
        );
      case 'learner.registered':
        return (
          label: 'Registered learner',
          icon: Icons.person_add_outlined,
          color: const Color(0xFFFF6B00),
        );
      case 'learner.updated':
        return (
          label: 'Updated learner',
          icon: Icons.edit_outlined,
          color: Colors.blue.shade700,
        );
      case 'learner.deleted':
        return (
          label: 'Deleted learner',
          icon: Icons.person_remove_outlined,
          color: Colors.red.shade700,
        );
      case 'learner.fingerprint_updated':
        return (
          label: 'Updated fingerprint',
          icon: Icons.fingerprint,
          color: Colors.purple.shade700,
        );
      case 'attendance.checkin':
        return (
          label: 'Checked in learner',
          icon: Icons.login,
          color: Colors.green.shade700,
        );
      case 'attendance.checkout':
        return (
          label: 'Checked out learner',
          icon: Icons.logout,
          color: Colors.green.shade700,
        );
      case 'nfc_card.assigned':
        return (
          label: 'Assigned NFC card',
          icon: Icons.nfc,
          color: const Color(0xFFFF6B00),
        );
      case 'nfc_card.cleared_cohort':
        return (
          label: 'Cleared cohort NFC cards',
          icon: Icons.clear,
          color: Colors.orange.shade700,
        );
      case 'report.session_submitted':
        return (
          label: 'Submitted session report',
          icon: Icons.upload_file_outlined,
          color: Colors.blue.shade700,
        );
      case 'report.cohort_final_submitted':
        return (
          label: 'Submitted final report',
          icon: Icons.verified_outlined,
          color: Colors.green.shade700,
        );
      default:
        return (
          label: action,
          icon: Icons.info_outline,
          color: Colors.grey.shade600,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ACTIVITY LOG'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B00),
              ),
            )
          : _logs.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: const Color(0xFFFF6B00),
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final log = _logs[i];
                      final desc = _describeAction(log['action'] ?? '');
                      return _LogRow(
                        icon: desc.icon,
                        color: desc.color,
                        label: desc.label,
                        time: _formatTime(log['created_at']),
                        resource: log['resource_type'] ?? '',
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 60,
            color: Color(0xFF888888),
          ),
          SizedBox(height: 16),
          Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String time;
  final String resource;

  const _LogRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.time,
    required this.resource,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  resource,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}