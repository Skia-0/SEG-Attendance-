class Coordinator {
  final String coordinatorId;
  final String fullName;
  final String phone;
  final String hubId;
  final String? hubName;
  final String? hubLocation;

  Coordinator({
    required this.coordinatorId,
    required this.fullName,
    required this.phone,
    required this.hubId,
    this.hubName,
    this.hubLocation,
  });

  factory Coordinator.fromJson(Map<String, dynamic> json) {
    return Coordinator(
      coordinatorId: json['coordinator_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      hubId: json['hub_id']?.toString() ?? '',
      hubName: json['hub_name']?.toString(),
      hubLocation: json['hub_location']?.toString(),
    );
  }
}