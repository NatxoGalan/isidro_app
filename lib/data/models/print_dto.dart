/// Estados de la cola de impresión
import 'package:cloud_firestore/cloud_firestore.dart';

enum PrintStatus {
  pending,
  printing,
  printed,
  failed,
}

/// Tipos de impresión
enum PrintType {
  kitchen,
  comanda,
  bill,
}

extension PrintTypeExtension on PrintType {
  String get displayName {
    switch (this) {
      case PrintType.kitchen:
        return 'Cocina';
      case PrintType.comanda:
        return 'Comanda';
      case PrintType.bill:
        return 'Cuenta';
    }
  }
}

/// Ticket en la cola de impresión
class PrintQueueTicket {
  final String id;
  final String orderId;
  final String tableNumber;
  final PrintType type;
  final List<PrintItemData> items;
  final String? notes;
  final DateTime createdAt;
  final DateTime? printedAt;
  final PrintStatus status;
  final String escPosHex;
  final int itemsCount;

  const PrintQueueTicket({
    required this.id,
    required this.orderId,
    required this.tableNumber,
    required this.type,
    required this.items,
    this.notes,
    required this.createdAt,
    this.printedAt,
    this.status = PrintStatus.pending,
    required this.escPosHex,
    required this.itemsCount,
  });

  String get targetDisplayName {
    switch (type) {
      case PrintType.kitchen:
        return 'Cocina';
      case PrintType.comanda:
        return 'Camarero';
      case PrintType.bill:
        return 'Caja';
    }
  }

  PrintQueueTicket copyWith({
    String? id,
    String? orderId,
    String? tableNumber,
    PrintType? type,
    List<PrintItemData>? items,
    String? notes,
    DateTime? createdAt,
    DateTime? printedAt,
    PrintStatus? status,
    String? escPosHex,
    int? itemsCount,
  }) {
    return PrintQueueTicket(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      tableNumber: tableNumber ?? this.tableNumber,
      type: type ?? this.type,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      printedAt: printedAt ?? this.printedAt,
      status: status ?? this.status,
      escPosHex: escPosHex ?? this.escPosHex,
      itemsCount: itemsCount ?? this.itemsCount,
    );
  }

  factory PrintQueueTicket.fromMap(Map<String, dynamic> map) {
    return PrintQueueTicket(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      tableNumber: map['tableNumber'] ?? '',
      type: PrintType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PrintType.kitchen,
      ),
      items: (map['items'] as List?)?.map((e) => PrintItemData.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      printedAt: (map['printedAt'] as Timestamp?)?.toDate(),
      status: PrintStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PrintStatus.pending,
      ),
      escPosHex: map['escPosHex'] ?? '',
      itemsCount: map['itemsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'tableNumber': tableNumber,
      'type': type.name,
      'items': items.map((i) => i.toMap()).toList(),
      'notes': notes,
      'createdAt': createdAt,
      'printedAt': printedAt,
      'status': status.name,
      'escPosHex': escPosHex,
      'itemsCount': itemsCount,
    };
  }
}

/// Item simplificado para tickets de impresión
class PrintItemData {
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final List<String> modifiers;
  final String notes;
  final bool isTakeaway;

  const PrintItemData({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.modifiers = const [],
    this.notes = '',
    this.isTakeaway = false,
  });

  factory PrintItemData.fromMap(Map<String, dynamic> map) {
    return PrintItemData(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      modifiers: (map['modifiers'] as List?)?.cast<String>() ?? [],
      notes: map['notes'] ?? '',
      isTakeaway: map['isTakeaway'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'modifiers': modifiers,
      'notes': notes,
      'isTakeaway': isTakeaway,
    };
  }
}