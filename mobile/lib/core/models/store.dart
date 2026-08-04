class Store {
  final int id;
  final String name;
  final String address;

  Store({required this.id, required this.name, required this.address});

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }
}
