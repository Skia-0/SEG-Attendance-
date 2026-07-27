import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportsHistoryScreen extends StatefulWidget {
  const ReportsHistoryScreen({super.key});

  @override
  State<ReportsHistoryScreen> createState() =>
      _ReportsHistoryScreenState();
}

class _ReportsHistoryScreenState
    extends State<ReportsHistoryScreen> {
  final _api = ApiService();
  List<dynamic> _reports = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      String? type;
      if (_filter == 'session') type = 'session';
      if (_filter == 'cohort_final') type = 'cohort_final';

      final res = await _api.listReports(type: type);
      _reports = res.data as List<dynamic>;
    } catch (_) {
      _reports = [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SUBMITTED REPORTS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF9F9F9),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  active: _filter == 'all',
                  onTap: () {
                    setState(() => _filter = 'all');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Session',
                  active: _filter == 'session',
                  onTap: () {
                    setState(() => _filter = 'session');
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Cohort Final',
                  active: _filter == 'cohort_final',
                  onTap: () {
                    setState(() => _filter = 'cohort_final');
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6B00),
                    ),
                  )
                : _reports.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: const Color(0xFFFF6B00),
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reports.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            return _ReportCard(
                              report: _reports[i],
                              formatDate: _formatDate,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 60,
            color: Color(0xFF888888),
          ),
          SizedBox(height: 16),
          Text(
            'No reports submitted yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Submit session or cohort reports to see them here',
            style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF6B00) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFFFF6B00)
                : const Color(0xFFDDDDDD),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final dynamic report;
  final String Function(String?) formatDate;

  const _ReportCard({
    required this.report,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final type = report['report_type'] ?? '';
    final data = report['data'] as Map<String, dynamic>? ?? {};
    final submittedAt = formatDate(report['submitted_at']);
    final isSession = type == 'session';

    final title = isSession
        ? (data['session_title'] ?? 'Session')
        : (data['cohort_name'] ?? 'Cohort');
    final subtitle = isSession
        ? (data['cohort_name'] ?? '')
        : 'Final Report';

    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSession
                      ? const Color(0xFFFFF3E0)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSession
                      ? Icons.event_note_outlined
                      : Icons.verified_outlined,
                  color: isSession
                      ? const Color(0xFFFF6B00)
                      : Colors.green.shade700,
                  size: 20,
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SUBMITTED',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
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
                const Icon(
                  Icons.access_time,
                  size: 12,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 6),
                Text(
                  submittedAt,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isSession && data['attended_count'] != null)
                  Text(
                    '${data['attended_count']}/${data['total_learners']} attended',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFF6B00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (!isSession && data['certified_count'] != null)
                  Text(
                    '${data['certified_count']}/${data['total_learners']} certified',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}