import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/learner.dart';
import 'learner_detail_screen.dart';
import 'register_learner_screen.dart';

class LearnersListScreen extends StatefulWidget {
  final String cohortId;
  final String cohortName;

  const LearnersListScreen({
    super.key,
    required this.cohortId,
    required this.cohortName,
  });

  @override
  State<LearnersListScreen> createState() =>
      _LearnersListScreenState();
}

class _LearnersListScreenState extends State<LearnersListScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  List<Learner> _learners = [];
  List<Learner> _filtered = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getLearnersBycohort(widget.cohortId);
      final data = res.data as List<dynamic>;
      _learners = data.map((j) => Learner.fromJson(j)).toList();
      _applyFilter();
    } catch (_) {
      _learners = [];
      _filtered = [];
    }
    setState(() => _loading = false);
  }

  void _applyFilter() {
    if (_query.trim().isEmpty) {
      _filtered = _learners;
    } else {
      final q = _query.toLowerCase();
      _filtered = _learners.where((l) {
        return l.fullName.toLowerCase().contains(q) ||
            l.segId.toLowerCase().contains(q);
      }).toList();
    }
  }

  void _openLearner(Learner l) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearnerDetailScreen(learnerId: l.learnerId),
      ),
    );
    _load();
  }

  void _addLearner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterLearnerScreen(
          cohortId: widget.cohortId,
          cohortName: widget.cohortName,
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
        title: const Text('LEARNERS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
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
                  '${_learners.length} Learner${_learners.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFFFF6B00),
                  onChanged: (v) {
                    setState(() {
                      _query = v;
                      _applyFilter();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name or SEG ID',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: const Color(0xFFFF6B00),
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final l = _filtered[i];
                            return _LearnerCard(
                              learner: l,
                              onTap: () => _openLearner(l),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addLearner,
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Add Learner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _query.isEmpty
                ? Icons.people_outline
                : Icons.search_off,
            size: 60,
            color: const Color(0xFF888888),
          ),
          const SizedBox(height: 16),
          Text(
            _query.isEmpty
                ? 'No learners yet'
                : 'No matches found',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _query.isEmpty
                ? 'Tap "Add Learner" to get started'
                : 'Try a different search',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnerCard extends StatelessWidget {
  final Learner learner;
  final VoidCallback onTap;

  const _LearnerCard({required this.learner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFF3E0),
                child: Text(
                  learner.fullName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
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
                      learner.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      learner.segId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (learner.nfcUid != null &&
                      learner.nfcUid!.isNotEmpty)
                    _Badge(
                      icon: Icons.nfc,
                      color: const Color(0xFFFF6B00),
                    ),
                  if (learner.fingerprintEnrolled)
                    _Badge(
                      icon: Icons.fingerprint,
                      color: Colors.green.shade700,
                    ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF888888),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Badge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 12, color: color),
      ),
    );
  }
}