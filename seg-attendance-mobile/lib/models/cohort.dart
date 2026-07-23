class Cohort {
  final String cohortId;
  final String name;
  final String hubId;
  final String? startDate;
  final String? endDate;
  final int minAttendancePercent;
  final int? learnerCount;

  Cohort({
    required this.cohortId,
    required this.name,
    required this.hubId,
    this.startDate,
    this.endDate,
    required this.minAttendancePercent,
    this.learnerCount,
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      cohortId: json['cohort_id'] ?? '',
      name: json['name'] ?? '',
      hubId: json['hub_id'] ?? '',
      startDate: json['start_date'],
      endDate: json['end_date'],
      minAttendancePercent: json['min_attendance_percent'] ?? 80,
      learnerCount: json['learner_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cohort_id': cohortId,
      'name': name,
      'hub_id': hubId,
      'start_date': startDate,
      'end_date': endDate,
      'min_attendance_percent': minAttendancePercent,
      'learner_count': learnerCount,
    };
  }
}
