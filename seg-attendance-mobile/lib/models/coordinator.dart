class Coordinator {
  final String coordinatorId;
  final String fullName;
  final String phone;
  final String hubId;
  final String? createdAt;

  Coordinator({
    required this.coordinatorId,
    required this.fullName,
    required this.phone,
    required this.hubId,
    this.createdAt,
  });

  factory Coordinator.fromJson(Map<String, dynamic> json) {
    return Coordinator(
      coordinatorId: json['coordinator_id'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      hubId: json['hub_id'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinator_id': coordinatorId,
      'full_name': fullName,
      'phone': phone,
      'hub_id': hubId,
      'created_at': createdAt,
    };
  }
}
