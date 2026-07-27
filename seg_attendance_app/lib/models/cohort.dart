class Cohort {
  final String cohortId;
  final String name;
  final String hubId;
  final String? startDate;
  final String? endDate;
  final int minAttendancePercent;
  final int learnerCount;
  final int sessionCount;
  final int? expectedSessions;
  final bool hasActiveSession;
  final String? code;

  Cohort({
    required this.cohortId,
    required this.name,
    required this.hubId,
    this.startDate,
    this.endDate,
    required this.minAttendancePercent,
    this.learnerCount = 0,
    this.sessionCount = 0,
    this.expectedSessions,
    this.hasActiveSession = false,
    this.code,
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      cohortId: json['cohort_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      hubId: json['hub_id']?.toString() ?? '',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      minAttendancePercent:
          (json['min_attendance_percent'] as num?)?.toInt() ?? 80,
      learnerCount: (json['learner_count'] as num?)?.toInt() ?? 0,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      expectedSessions:
          (json['expected_sessions'] as num?)?.toInt(),
      hasActiveSession: json['has_active_session'] == true,
      code: json['code']?.toString(),
    );
  }
}