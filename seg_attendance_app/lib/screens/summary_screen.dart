import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SummaryScreen extends StatefulWidget {
  final String cohortId;
  final String cohortName;

  const SummaryScreen({
    super.key,
    required this.cohortId,
    required this.cohortName,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _api = ApiService();
  List<dynamic> _summary = [];
  bool _loading = true;
  int _minThreshold = 80;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cohortRes = await _api.getCohort(widget.cohortId);
      final summaryRes =
          await _api.getCohortSummary(widget.cohortId);

      setState(() {
        _minThreshold = (cohortRes.data['min_attendance_percent']
                as num?)
                ?.toInt() ??
            80;
        _summary = summaryRes.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load summary'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  int get _certifiedCount =>
      _summary.where((l) => l['meets_threshold'] == true).length;

  int get _totalCount => _summary.length;

  int get _totalSessions {
    if (_summary.isEmpty) return 0;
    return (_summary.first['total_sessions'] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ATTENDANCE SUMMARY'),
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
          : Column(
              children: [
                _buildHeader(),
                _buildStats(),
                const Divider(height: 1),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.cohortName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFFFF6B00),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                'Certification threshold: $_minThreshold%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _StatCard(
            label: 'Learners',
            value: '$_totalCount',
            color: const Color(0xFF1A1A1A),
            icon: Icons.people_outline,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Sessions',
            value: '$_totalSessions',
            color: const Color(0xFFFF6B00),
            icon: Icons.event_outlined,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Certified',
            value: '$_certifiedCount',
            color: Colors.green.shade700,
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_summary.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 60,
                color: Color(0xFF888888),
              ),
              SizedBox(height: 16),
              Text(
                'No learners in this cohort yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      itemCount: _summary.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final learner = _summary[i];
        return _SummaryRow(learner: learner);
      },
    );
  }
}

// ─────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
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

class _SummaryRow extends StatelessWidget {
  final dynamic learner;
  const _SummaryRow({required this.learner});

  @override
  Widget build(BuildContext context) {
    final name = learner['full_name'] ?? 'Learner';
    final segId = learner['seg_id'] ?? '';
    final attended =
        (learner['sessions_attended'] as num?)?.toInt() ?? 0;
    final total =
        (learner['total_sessions'] as num?)?.toInt() ?? 0;
    final percent =
        (learner['attendance_percent'] as num?)?.toDouble() ?? 0.0;
    final meets = learner['meets_threshold'] == true;

    final barColor = meets
        ? Colors.green.shade700
        : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: meets
            ? Colors.white
            : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: meets
              ? const Color(0xFFEEEEEE)
              : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: meets
                    ? const Color(0xFFFFF3E0)
                    : Colors.red.shade50,
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: meets
                        ? const Color(0xFFFF6B00)
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      segId,
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
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: meets
                      ? Colors.green.shade700
                      : Colors.red.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      meets ? Icons.verified : Icons.cancel,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meets ? 'CERTIFIED' : 'NOT MET',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$attended of $total sessions',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                          ),
                        ),
                        Text(
                          '${percent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 6,
                        backgroundColor:
                            const Color(0xFFEEEEEE),
                        valueColor: AlwaysStoppedAnimation(
                          barColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}