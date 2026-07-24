import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/attendance_record.dart';
import '../models/session.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final String cohortName;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.cohortName,
  });

  @override
  State<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _api = ApiService();
  SessionModel? _session;
  List<AttendanceRecord> _records = [];
  bool _loading = true;
  bool _submitting = false;
  bool _alreadySubmitted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sessionRes = await _api.getSession(widget.sessionId);
      final attendanceRes =
          await _api.getAttendance(widget.sessionId);

      _session = SessionModel.fromJson(sessionRes.data);
      final data = attendanceRes.data as List<dynamic>;
      _records =
          data.map((j) => AttendanceRecord.fromJson(j)).toList();
    } catch (_) {
      _session = null;
    }
    setState(() => _loading = false);
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _submitReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Session Report?'),
        content: const Text(
          'This session\'s full attendance data will be '
          'submitted to the SEG central repository. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      await _api.submitSessionReport(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _alreadySubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted to SEG ✓'),
          backgroundColor: Color(0xFFFF6B00),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final msg = e.toString().contains('already submitted')
          ? 'Report already submitted for this session'
          : 'Failed to submit report';
      if (msg.contains('already')) {
        setState(() => _alreadySubmitted = true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B00),
          ),
        ),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('SESSION')),
        body: const Center(child: Text('Session not found')),
      );
    }

    final s = _session!;
    final completeCount =
        _records.where((r) => r.isComplete).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SESSION DETAIL'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: s.isEnded
                            ? Colors.green.shade700
                            : const Color(0xFFFF6B00),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.isEnded ? 'ENDED' : 'ACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (_alreadySubmitted) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SUBMITTED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Started',
                    value: _formatDate(s.startedAt),
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Ended',
                    value: s.endedAt != null
                        ? _formatDate(s.endedAt)
                        : 'Not ended',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Attendance',
                    value: '$completeCount / ${_records.length} complete',
                  ),
                ],
              ),
            ),
          ),
          if (s.isEnded && !_alreadySubmitted)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitReport,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _submitting
                        ? 'Submitting...'
                        : 'Submit Session Report To SEG',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ATTENDANCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF888888),
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          Expanded(
            child: _records.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No attendance records',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: _records.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final r = _records[i];
                      return _RecordRow(
                        record: r,
                        inTime: _formatTime(r.checkedInAt),
                        outTime: _formatTime(r.checkedOutAt),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final AttendanceRecord record;
  final String inTime;
  final String outTime;

  const _RecordRow({
    required this.record,
    required this.inTime,
    required this.outTime,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String status;

    if (record.isComplete) {
      color = Colors.green.shade700;
      icon = Icons.check_circle;
      status = 'COMPLETE';
    } else if (record.hasCheckedIn) {
      color = const Color(0xFFFF6B00);
      icon = Icons.login;
      status = 'PARTIAL';
    } else {
      color = Colors.grey.shade500;
      icon = Icons.radio_button_unchecked;
      status = 'ABSENT';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
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
                Row(
                  children: [
                    Text(
                      record.segId ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF888888),
                      ),
                    ),
                    if (record.hasCheckedIn) ...[
                      const SizedBox(width: 8),
                      Text(
                        inTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF6B00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        ' → ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                      Text(
                        outTime.isEmpty ? '—' : outTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: outTime.isEmpty
                              ? Colors.grey
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
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
    );
  }
}