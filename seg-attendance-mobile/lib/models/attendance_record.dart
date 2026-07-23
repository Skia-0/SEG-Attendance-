class AttendanceRecord {
  final String recordId;
  final String sessionId;
  final String learnerId;
  final String? checkedInAt;
  final String? checkedOutAt;
  final String verificationMethod;
  final bool isComplete;
  final String? segId;
  final String? fullName;

  AttendanceRecord({
    required this.recordId,
    required this.sessionId,
    required this.learnerId,
    this.checkedInAt,
    this.checkedOutAt,
    required this.verificationMethod,
    required this.isComplete,
    this.segId,
    this.fullName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      recordId: json['record_id'] ?? '',
      sessionId: json['session_id'] ?? '',
      learnerId: json['learner_id'] ?? '',
      checkedInAt: json['checked_in_at'],
      checkedOutAt: json['checked_out_at'],
      verificationMethod: json['verification_method'] ?? '',
      isComplete: json['is_complete'] ?? false,
      segId: json['seg_id'],
      fullName: json['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'record_id': recordId,
      'session_id': sessionId,
      'learner_id': learnerId,
      'checked_in_at': checkedInAt,
      'checked_out_at': checkedOutAt,
      'verification_method': verificationMethod,
      'is_complete': isComplete,
      'seg_id': segId,
      'full_name': fullName,
    };
  }
}
