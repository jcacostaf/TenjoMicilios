class ConsumerAddress {
  final String id;
  final String label;
  final String addressText;
  final double latitude;
  final double longitude;

  ConsumerAddress({
    required this.id,
    required this.label,
    required this.addressText,
    required this.latitude,
    required this.longitude,
  });

  factory ConsumerAddress.fromJson(Map<String, dynamic> json) {
    return ConsumerAddress(
      id: json['id'] as String,
      label: json['label'] as String,
      addressText: json['addressText'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'addressText': addressText,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
