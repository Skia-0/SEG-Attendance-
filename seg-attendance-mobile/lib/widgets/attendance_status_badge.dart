import 'package:flutter/material.dart';

class AttendanceStatusBadge extends StatelessWidget {
  final String status;

  const AttendanceStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'complete':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        break;
      case 'checked in':
      case 'checked_in':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
