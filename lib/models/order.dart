// Shared order and vendor product models

class OrderItemDetail {
  String productId;
  String productName;
  int qty;
  double price;

  OrderItemDetail({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'qty': qty,
    'price': price,
  };
  factory OrderItemDetail.fromJson(Map<String, dynamic> j) => OrderItemDetail(
    productId: j['productId'] as String,
    productName: j['productName'] as String,
    qty: (j['qty'] as num).toInt(),
    price: (j['price'] as num).toDouble(),
  );
}

class Order {
  String id;
  String customerName;
  String customerEmail;
  String status; // Pending, On Delivery, Completed
  List<OrderItemDetail> items;
  String? vendorId;
  String? driverId;
  DateTime timestamp;
  String? address;
  double totalAmount;

  Order({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.status,
    required this.items,
    required this.timestamp,
    this.vendorId,
    this.driverId,
    this.address,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'status': status,
    'items': items.map((e) => e.toJson()).toList(),
    'vendorId': vendorId,
    'driverId': driverId,
    'timestamp': timestamp.toIso8601String(),
    'address': address,
    'totalAmount': totalAmount,
  };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'] as String,
    customerName: j['customerName'] as String,
    customerEmail: j['customerEmail'] as String,
    status: j['status'] as String,
    items: ((j['items'] ?? []) as List)
        .map((e) => OrderItemDetail.fromJson(e))
        .toList(),
    vendorId: j['vendorId'] as String?,
    driverId: j['driverId'] as String?,
    timestamp: DateTime.parse(j['timestamp'] as String),
    address: j['address'] as String?,
    totalAmount: (j['totalAmount'] as num).toDouble(),
  );
}
