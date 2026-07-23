class Session {
  final String sessionId;
  final String cohortId;
  final String coordinatorId;
  final String? title;
  final String? startedAt;
  final String? endedAt;
  final bool checkinOpen;
  final bool checkoutOpen;

  Session({
    required this.sessionId,
    required this.cohortId,
    required this.coordinatorId,
    this.title,
    this.startedAt,
    this.endedAt,
    required this.checkinOpen,
    required this.checkoutOpen,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionId: json['session_id'] ?? '',
      cohortId: json['cohort_id'] ?? '',
      coordinatorId: json['coordinator_id'] ?? '',
      title: json['title'],
      startedAt: json['started_at'],
      endedAt: json['ended_at'],
      checkinOpen: json['checkin_open'] ?? false,
      checkoutOpen: json['checkout_open'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'cohort_id': cohortId,
      'coordinator_id': coordinatorId,
      'title': title,
      'started_at': startedAt,
      'ended_at': endedAt,
      'checkin_open': checkinOpen,
      'checkout_open': checkoutOpen,
    };
  }
}
