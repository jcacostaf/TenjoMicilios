enum HousingType { casa, apartamento }

class ConsumerAddress {
  final String id;
  final String label;
  final String addressText;
  final double latitude;
  final double longitude;
  final HousingType housingType;
  final String? additionalInfo;

  ConsumerAddress({
    required this.id,
    required this.label,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.housingType,
    this.additionalInfo,
  });

  factory ConsumerAddress.fromJson(Map<String, dynamic> json) {
    return ConsumerAddress(
      id: json['id'] as String,
      label: json['label'] as String,
      addressText: json['addressText'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      housingType: HousingType.values.firstWhere(
        (t) => t.name == json['housingType'],
        orElse: () => HousingType.casa,
      ),
      additionalInfo: json['additionalInfo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'addressText': addressText,
      'latitude': latitude,
      'longitude': longitude,
      'housingType': housingType.name,
      'additionalInfo': additionalInfo,
    };
  }
}
