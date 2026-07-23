class Learner {
  final String learnerId;
  final String segId;
  final String fullName;
  final String? phone;
  final String cohortId;
  final String? nfcUid;
  final bool fingerprintEnrolled;
  final String? registeredAt;

  Learner({
    required this.learnerId,
    required this.segId,
    required this.fullName,
    this.phone,
    required this.cohortId,
    this.nfcUid,
    required this.fingerprintEnrolled,
    this.registeredAt,
  });

  factory Learner.fromJson(Map<String, dynamic> json) {
    return Learner(
      learnerId: json['learner_id'] ?? '',
      segId: json['seg_id'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      cohortId: json['cohort_id'] ?? '',
      nfcUid: json['nfc_uid'],
      fingerprintEnrolled: json['fingerprint_enrolled'] ?? false,
      registeredAt: json['registered_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learner_id': learnerId,
      'seg_id': segId,
      'full_name': fullName,
      'phone': phone,
      'cohort_id': cohortId,
      'nfc_uid': nfcUid,
      'fingerprint_enrolled': fingerprintEnrolled,
      'registered_at': registeredAt,
    };
  }
}
