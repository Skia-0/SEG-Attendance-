import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/cohort.dart';
import 'start_session_screen.dart';
import 'summary_screen.dart';
import 'learners_list_screen.dart';
import 'session_detail_screen.dart';

class CohortDetailScreen extends StatefulWidget {
  final String cohortId;
  const CohortDetailScreen({super.key, required this.cohortId});

  @override
  State<CohortDetailScreen> createState() =>
      _CohortDetailScreenState();
}

class _CohortDetailScreenState extends State<CohortDetailScreen> {
  final _api = ApiService();
  Cohort? _cohort;
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cohortRes = await _api.getCohort(widget.cohortId);
      final sessionsRes =
          await _api.getSessionsByCohor(widget.cohortId);

      setState(() {
        _cohort = Cohort.fromJson(cohortRes.data);
        _sessions = sessionsRes.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load cohort'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openLearners() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearnersListScreen(
          cohortId: widget.cohortId,
          cohortName: _cohort!.name,
        ),
      ),
    );
    _load();
  }

  void _viewSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryScreen(
          cohortId: widget.cohortId,
          cohortName: _cohort!.name,
        ),
      ),
    );
  }

  void _startNewSession() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartSessionScreen(
          cohortId: widget.cohortId,
          cohortName: _cohort!.name,
        ),
      ),
    );
    _load();
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Cohort?'),
        content: Text(
          'This will permanently delete "${_cohort?.name ?? "this cohort"}", '
          'all its sessions, learners, and attendance records. '
          'This cannot be undone.',
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
      await _api.deleteCohort(widget.cohortId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cohort deleted'),
          backgroundColor: Color(0xFFFF6B00),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete cohort'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitFinalReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Final Report?'),
        content: const Text(
          'This will submit the final attendance report for '
          'this cohort to the SEG central repository. '
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

    try {
      await _api.submitCohortFinalReport(widget.cohortId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted to SEG ✓'),
            backgroundColor: Color(0xFFFF6B00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().contains('already submitted')
          ? 'Report already submitted for this cohort'
          : 'Failed to submit report';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('COHORT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'delete') _confirmDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Cohort'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B00),
              ),
            )
          : _cohort == null
              ? const Center(child: Text('Cohort not found'))
              : RefreshIndicator(
                  color: const Color(0xFFFF6B00),
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildHeader(),
                      _buildActions(),
                      _buildSessionsSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
      floatingActionButton: _cohort == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _startNewSession,
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'New Session',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _cohort!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                icon: Icons.person_outline,
                label: '${_cohort!.learnerCount} Learners',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.event_outlined,
                label: '${_cohort!.sessionCount} Sessions',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.check_circle_outline,
                label:
                    '${_cohort!.minAttendancePercent}% min',
              ),
            ],
          ),
          if (_cohort!.startDate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Runs ${_cohort!.startDate} → ${_cohort!.endDate ?? "TBD"}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.people_outline,
                  label: 'Learners',
                  onTap: _openLearners,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bar_chart_outlined,
                  label: 'Summary',
                  onTap: _viewSummary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _submitFinalReport,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Submit Final Report To SEG'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B00),
                side: const BorderSide(color: Color(0xFFFF6B00)),
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sessions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                '${_sessions.length} total',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_sessions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 40,
                    color: Color(0xFF888888),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No sessions yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap "New Session" to get started',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._sessions
                .map((s) => _SessionTile(session: s,
                    cohortName: _cohort!.name,))
                .toList(),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDDDDD)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFFF6B00), size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final dynamic session;
  final String cohortName;
  const _SessionTile({
    required this.session,
    required this.cohortName,
  });

  @override
  Widget build(BuildContext context) {
    final title = session['title'] ?? 'Session';
    final sessionId = session['session_id']?.toString() ?? '';
    final endedAt = session['ended_at'];
    final checkinOpen = session['checkin_open'] == true;
    final checkoutOpen = session['checkout_open'] == true;
    final attendance = session['attendance_count'] ?? 0;

    String status;
    Color statusColor;

    if (endedAt != null) {
      status = 'COMPLETE';
      statusColor = Colors.green.shade700;
    } else if (checkinOpen) {
      status = 'CHECK-IN OPEN';
      statusColor = const Color(0xFFFF6B00);
    } else if (checkoutOpen) {
      status = 'CHECK-OUT OPEN';
      statusColor = const Color(0xFFFF6B00);
    } else {
      status = 'ACTIVE';
      statusColor = const Color(0xFF1A1A1A);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SessionDetailScreen(
                  sessionId: sessionId,
                  cohortName: cohortName,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$attendance attended',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF888888),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}