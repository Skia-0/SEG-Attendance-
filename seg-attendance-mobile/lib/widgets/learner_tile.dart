import 'package:flutter/material.dart';
import 'attendance_status_badge.dart';

class LearnerTile extends StatelessWidget {
  final String segId;
  final String fullName;
  final String status;
  final String? timeText;

  const LearnerTile({
    super.key,
    required this.segId,
    required this.fullName,
    required this.status,
    this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(segId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.emerald, fontWeight: FontWeight.bold)),
            if (timeText != null) ...[
              const SizedBox(height: 2),
              Text(timeText!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ],
        ),
        trailing: AttendanceStatusBadge(status: status),
      ),
    );
  }
}
