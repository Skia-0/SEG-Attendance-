import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _cohortIdController = TextEditingController();

  @override
  void dispose() {
    _cohortIdController.dispose();
    super.dispose();
  }

  void _loadSummary() async {
    final cohortId = _cohortIdController.text.trim();
    if (cohortId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Cohort ID")),
      );
      return;
    }

    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final success = await provider.loadSummary(cohortId);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? "Failed to load cohort summary."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cohort summary ledger"),
        backgroundColor: Colors.emerald,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Cohort Certification Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.emerald),
            ),
            const SizedBox(height: 16),
            
            // Cohort ID Input Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cohortIdController,
                    decoration: InputDecoration(
                      labelText: "Cohort ID",
                      prefixIcon: const Icon(Icons.class_),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _loadSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Load"),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Results Section
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.emerald))
                  : provider.summaryList.isEmpty
                      ? const Center(
                          child: Text(
                            "Enter Cohort ID and click Load to see certification summary.",
                            textAlign: Center,
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.emerald.shade50),
                              border: TableBorder.all(color: Colors.grey.shade200, width: 1, borderRadius: BorderRadius.circular(8)),
                              columns: const [
                                DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("SEG ID", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Sessions", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("%", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Certified", style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: provider.summaryList.map((learner) {
                                final bool meetsThreshold = learner['meets_threshold'] ?? false;
                                final double percent = (learner['attendance_percent'] as num?)?.toDouble() ?? 0.0;
                                final Color rowColor = meetsThreshold ? Colors.transparent : Colors.red.shade50;

                                return DataRow(
                                  color: MaterialStateProperty.all(rowColor),
                                  cells: [
                                    DataCell(Text(
                                      learner['full_name'] ?? '—',
                                      style: TextStyle(fontWeight: meetsThreshold ? FontWeight.normal : FontWeight.bold),
                                    )),
                                    DataCell(Text(
                                      learner['seg_id'] ?? '—',
                                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                                    )),
                                    DataCell(Center(
                                      child: Text("${learner['sessions_attended'] ?? 0} / ${learner['total_sessions'] ?? 0}"),
                                    )),
                                    DataCell(Center(
                                      child: Text(
                                        "${percent.toStringAsFixed(1)}%",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: meetsThreshold ? Colors.emerald.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                    )),
                                    DataCell(Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: meetsThreshold ? Colors.green.shade100 : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          meetsThreshold ? "YES" : "NO",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: meetsThreshold ? Colors.green.shade900 : Colors.red.shade900,
                                          ),
                                        ),
                                      ),
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
