class DriverProfile {
  final int id;
  final String name;

  DriverProfile({required this.id, required this.name});

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(id: json['id'] as int, name: json['name'] as String);
  }
}
