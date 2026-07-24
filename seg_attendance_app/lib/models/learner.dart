class Learner {
  final String learnerId;
  final String segId;
  final String fullName;
  final String? phone;
  final String cohortId;
  final String? nfcUid;
  final bool fingerprintEnrolled;

  Learner({
    required this.learnerId,
    required this.segId,
    required this.fullName,
    this.phone,
    required this.cohortId,
    this.nfcUid,
    this.fingerprintEnrolled = false,
  });

  factory Learner.fromJson(Map<String, dynamic> json) {
    return Learner(
      learnerId: json['learner_id']?.toString() ?? '',
      segId: json['seg_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      cohortId: json['cohort_id']?.toString() ?? '',
      nfcUid: json['nfc_uid']?.toString(),
      fingerprintEnrolled: json['fingerprint_enrolled'] == true,
    );
  }
}