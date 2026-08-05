class Store {
  final int id;
  final String name;
  final String address;
  final String? category;

  Store({required this.id, required this.name, required this.address, this.category});

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      category: json['category'] as String?,
    );
  }
}
