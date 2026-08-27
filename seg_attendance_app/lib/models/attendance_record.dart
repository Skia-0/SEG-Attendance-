class AttendanceRecord {
  final String recordId;
  final String sessionId;
  final String learnerId;
  final String? segId;
  final String? fullName;
  final String? checkedInAt;
  final String? checkedOutAt;
  final String verificationMethod;
  final String? overrideReason;
  final bool isComplete;
  final String? photoBase64;

  AttendanceRecord({
    required this.recordId,
    required this.sessionId,
    required this.learnerId,
    this.segId,
    this.fullName,
    this.checkedInAt,
    this.checkedOutAt,
    required this.verificationMethod,
    this.overrideReason,
    this.isComplete = false,
    this.photoBase64,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      recordId: json['record_id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      learnerId: json['learner_id']?.toString() ?? '',
      segId: json['seg_id']?.toString(),
      fullName: json['full_name']?.toString(),
      checkedInAt: json['checked_in_at']?.toString(),
      checkedOutAt: json['checked_out_at']?.toString(),
      verificationMethod:
          json['verification_method']?.toString() ?? 'nfc',
      overrideReason: json['override_reason']?.toString(),
      isComplete: json['is_complete'] == true,
      photoBase64: json['photo_base64']?.toString(),
    );
  }

  bool get hasCheckedIn => checkedInAt != null;
  bool get hasCheckedOut => checkedOutAt != null;
}