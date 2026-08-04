enum OrderStatus { pendiente, preparando, listo, enCamino, entregado }

class OrderItemInput {
  final int productId;
  final int quantity;

  OrderItemInput({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': null,
        'unitPrice': null,
        'quantity': quantity,
      };
}

class OrderItemLine {
  final String productName;
  final double unitPrice;
  final int quantity;

  OrderItemLine({required this.productName, required this.unitPrice, required this.quantity});

  factory OrderItemLine.fromJson(Map<String, dynamic> json) {
    return OrderItemLine(
      productName: json['productName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}

class StoreOrder {
  final int id;
  final int storeId;
  final int? driverId;
  final OrderStatus status;
  final String? deliveryAddressText;
  final String? recipientName;
  final String? note;
  final double total;
  final List<OrderItemLine> items;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;

  StoreOrder({
    required this.id,
    required this.storeId,
    required this.driverId,
    required this.status,
    required this.deliveryAddressText,
    required this.recipientName,
    required this.note,
    required this.total,
    required this.items,
    required this.createdAt,
    required this.acceptedAt,
    required this.deliveredAt,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    return StoreOrder(
      id: json['id'] as int,
      storeId: json['storeId'] as int,
      driverId: json['driverId'] as int?,
      status: OrderStatus.values[json['status'] as int],
      deliveryAddressText: json['deliveryAddressText'] as String?,
      recipientName: json['recipientName'] as String?,
      note: json['note'] as String?,
      total: (json['total'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((j) => OrderItemLine.fromJson(j as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt'] as String) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt'] as String) : null,
    );
  }
}

class AvailableOrder {
  final int orderId;
  final int storeId;
  final String storeName;
  final String? storeAddress;
  final String? deliveryAddressText;
  final String? recipientName;
  final String? note;
  final double total;
  final List<OrderItemLine> items;
  final OrderStatus status;
  final DateTime createdAt;
  final double? distanceMeters;

  AvailableOrder({
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.storeAddress,
    required this.deliveryAddressText,
    required this.recipientName,
    required this.note,
    required this.total,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.distanceMeters,
  });

  factory AvailableOrder.fromJson(Map<String, dynamic> json) {
    return AvailableOrder(
      orderId: json['orderId'] as int,
      storeId: json['storeId'] as int,
      storeName: json['storeName'] as String,
      storeAddress: json['storeAddress'] as String?,
      deliveryAddressText: json['deliveryAddressText'] as String?,
      recipientName: json['recipientName'] as String?,
      note: json['note'] as String?,
      total: (json['total'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((j) => OrderItemLine.fromJson(j as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values[json['status'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );
  }
}

class ActiveOrder {
  final int orderId;
  final int storeId;
  final String storeName;
  final String? storeAddress;
  final double? storeLatitude;
  final double? storeLongitude;
  final String? deliveryAddressText;
  final String? recipientName;
  final String? note;
  final double total;
  final List<OrderItemLine> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  ActiveOrder({
    required this.orderId,
    required this.storeId,
    required this.storeName,
    required this.storeAddress,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.deliveryAddressText,
    required this.recipientName,
    required this.note,
    required this.total,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.acceptedAt,
  });

  factory ActiveOrder.fromJson(Map<String, dynamic> json) {
    return ActiveOrder(
      orderId: json['orderId'] as int,
      storeId: json['storeId'] as int,
      storeName: json['storeName'] as String,
      storeAddress: json['storeAddress'] as String?,
      storeLatitude: (json['storeLatitude'] as num?)?.toDouble(),
      storeLongitude: (json['storeLongitude'] as num?)?.toDouble(),
      deliveryAddressText: json['deliveryAddressText'] as String?,
      recipientName: json['recipientName'] as String?,
      note: json['note'] as String?,
      total: (json['total'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((j) => OrderItemLine.fromJson(j as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values[json['status'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt'] as String) : null,
    );
  }
}
