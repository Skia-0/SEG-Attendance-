class SessionModel {
  final String sessionId;
  final String cohortId;
  final String coordinatorId;
  final String title;
  final String? startedAt;
  final String? endedAt;
  final bool checkinOpen;
  final bool checkoutOpen;
  final int attendanceCount;

  SessionModel({
    required this.sessionId,
    required this.cohortId,
    required this.coordinatorId,
    required this.title,
    this.startedAt,
    this.endedAt,
    this.checkinOpen = false,
    this.checkoutOpen = false,
    this.attendanceCount = 0,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['session_id']?.toString() ?? '',
      cohortId: json['cohort_id']?.toString() ?? '',
      coordinatorId: json['coordinator_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      startedAt: json['started_at']?.toString(),
      endedAt: json['ended_at']?.toString(),
      checkinOpen: json['checkin_open'] == true,
      checkoutOpen: json['checkout_open'] == true,
      attendanceCount:
          (json['attendance_count'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isEnded => endedAt != null;
  bool get isActive => !isEnded;
}