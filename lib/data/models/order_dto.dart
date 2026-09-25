import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { draft, pending, ready, served, paid, cancelled }
enum OrderItemStatus { pending, ready, served }
enum PrinterTarget { bar, kitchen, both }

class OrderEntity {
  final String id;
  final String venueId;
  final String tableId;
  final OrderStatus status;
  final List<OrderItemEntity> items;
  final PrinterTarget printerTarget;
  final String cashierNotes;
  final String kitchenNotes;
  final bool isTakeaway;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentToKitchenAt;
  final DateTime? servedAt;

  const OrderEntity({
    required this.id,
    required this.venueId,
    required this.tableId,
    this.status = OrderStatus.pending,
    this.items = const [],
    this.printerTarget = PrinterTarget.both,
    this.cashierNotes = '',
    this.kitchenNotes = '',
    this.isTakeaway = false,
    required this.createdAt,
    required this.updatedAt,
    this.sentToKitchenAt,
    this.servedAt,
  });

  factory OrderEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderEntity(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      tableId: data['tableId'] ?? '',
      status: OrderStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      items: (data['items'] as List?)
          ?.map((i) => OrderItemEntity.fromMap(i as Map<String, dynamic>))
          .toList() ?? [],
      printerTarget: PrinterTarget.values.firstWhere(
        (t) => t.name == data['printerTarget'],
        orElse: () => PrinterTarget.both,
      ),
      cashierNotes: data['cashierNotes'] ?? '',
      kitchenNotes: data['kitchenNotes'] ?? '',
      isTakeaway: data['isTakeaway'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentToKitchenAt: (data['sentToKitchenAt'] as Timestamp?)?.toDate(),
      servedAt: (data['servedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'venueId': venueId,
    'tableId': tableId,
    'status': status.name,
    'items': items.map((i) => i.toMap()).toList(),
    'printerTarget': printerTarget.name,
    'cashierNotes': cashierNotes,
    'kitchenNotes': kitchenNotes,
    'isTakeaway': isTakeaway,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'sentToKitchenAt': sentToKitchenAt,
    'servedAt': servedAt,
  };
}

class OrderItemEntity {
  final String itemId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<AppliedModifier> modifiers;
  final String notes;
  final bool isTakeaway;
  final OrderItemStatus status;
  final DateTime createdAt;
  final int sentQuantity;
  final String categoryId;
  final String categoryName;

  const OrderItemEntity({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.modifiers = const [],
    this.notes = '',
    this.isTakeaway = false,
    this.status = OrderItemStatus.pending,
    required this.createdAt,
    this.sentQuantity = 0,
    this.categoryId = '',
    this.categoryName = '',
  });

  factory OrderItemEntity.fromMap(Map<String, dynamic> map) {
    return OrderItemEntity(
      itemId: map['itemId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      modifiers: (map['modifiers'] as List?)
          ?.map((m) => AppliedModifier.fromMap(m as Map<String, dynamic>))
          .toList() ?? [],
      notes: map['notes'] ?? '',
      isTakeaway: map['isTakeaway'] ?? false,
      status: OrderItemStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => OrderItemStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentQuantity: (map['sentQuantity'] as num?)?.toInt() ?? 0,
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
    );
  }

  /// Cantidad pendiente de enviar a cocina.
  int get unsentQuantity => (quantity - sentQuantity).clamp(0, quantity);

  OrderItemEntity copyWith({
    String? itemId,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    List<AppliedModifier>? modifiers,
    String? notes,
    bool? isTakeaway,
    OrderItemStatus? status,
    DateTime? createdAt,
    int? sentQuantity,
    String? categoryId,
    String? categoryName,
  }) {
    return OrderItemEntity(
      itemId: itemId ?? this.itemId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      modifiers: modifiers ?? this.modifiers,
      notes: notes ?? this.notes,
      isTakeaway: isTakeaway ?? this.isTakeaway,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sentQuantity: sentQuantity ?? this.sentQuantity,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'modifiers': modifiers.map((m) => m.toMap()).toList(),
    'notes': notes,
    'isTakeaway': isTakeaway,
    'status': status.name,
    'createdAt': createdAt,
    'sentQuantity': sentQuantity,
    'categoryId': categoryId,
    'categoryName': categoryName,
  };
}

class AppliedModifier {
  final String modifierId;
  final String modifierName;
  final String? optionId;
  final String? optionName;
  final double additionalPrice;

  const AppliedModifier({
    required this.modifierId,
    required this.modifierName,
    this.optionId,
    this.optionName,
    this.additionalPrice = 0.0,
  });

  factory AppliedModifier.fromMap(Map<String, dynamic> map) {
    return AppliedModifier(
      modifierId: map['modifierId'] ?? '',
      modifierName: map['modifierName'] ?? '',
      optionId: map['optionId'],
      optionName: map['optionName'],
      additionalPrice: (map['additionalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'modifierId': modifierId,
    'modifierName': modifierName,
    'optionId': optionId,
    'optionName': optionName,
    'additionalPrice': additionalPrice,
  };
}
