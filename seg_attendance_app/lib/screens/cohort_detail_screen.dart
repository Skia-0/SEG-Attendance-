import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/cohort.dart';
import 'register_learner_screen.dart';
import 'start_session_screen.dart';

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

  void _registerLearner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterLearnerScreen(
          cohortId: widget.cohortId,
          cohortName: _cohort!.name,
        ),
      ),
    );
    _load();
  }

  void _viewSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary — coming soon'),
        behavior: SnackBarBehavior.floating,
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
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.person_add_outlined,
              label: 'Add Learner',
              onTap: _registerLearner,
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
                .map((s) => _SessionTile(session: s))
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
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final title = session['title'] ?? 'Session';
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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
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
                          borderRadius: BorderRadius.circular(4),
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
    );
  }
}