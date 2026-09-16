import 'package:cloud_firestore/cloud_firestore.dart';

enum TableStatus { free, occupied, reserved, cleaning }

class TableEntity {
  final String id;
  final String venueId;
  final String zoneId;
  final String tableNumber;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;
  final DateTime? openedAt;
  final DateTime? lastActivityAt;
  final Map<String, double>? position;
  final String? notes;
  final bool hasItems;

  const TableEntity({
    required this.id,
    required this.venueId,
    required this.zoneId,
    required this.tableNumber,
    required this.capacity,
    this.status = TableStatus.free,
    this.currentOrderId,
    this.openedAt,
    this.lastActivityAt,
    this.position,
    this.notes,
    this.hasItems = false,
  });

  factory TableEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableEntity(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      zoneId: data['zoneId'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      capacity: data['capacity'] ?? 2,
      status: TableStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TableStatus.free,
      ),
      currentOrderId: data['currentOrderId'],
      openedAt: (data['openedAt'] as Timestamp?)?.toDate(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp?)?.toDate(),
      position: data['position']?.cast<String, double>(),
      notes: data['notes'],
      hasItems: data['hasItems'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'venueId': venueId,
    'zoneId': zoneId,
    'tableNumber': tableNumber,
    'capacity': capacity,
    'status': status.name,
    'currentOrderId': currentOrderId,
    'openedAt': openedAt,
    'lastActivityAt': lastActivityAt,
    'position': position,
    'notes': notes,
    'hasItems': hasItems,
  };

  TableEntity copyWith({
    String? id,
    String? venueId,
    String? zoneId,
    String? tableNumber,
    int? capacity,
    TableStatus? status,
    String? currentOrderId,
    DateTime? openedAt,
    DateTime? lastActivityAt,
    Map<String, double>? position,
    String? notes,
    bool? hasItems,
  }) {
    return TableEntity(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      zoneId: zoneId ?? this.zoneId,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      openedAt: openedAt ?? this.openedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      position: position ?? this.position,
      notes: notes ?? this.notes,
      hasItems: hasItems ?? this.hasItems,
    );
  }

  bool get isOccupied => status != TableStatus.free;
  String get shortId => 'Mesa $tableNumber';
}
