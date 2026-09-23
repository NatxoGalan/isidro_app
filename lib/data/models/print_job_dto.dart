import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado de un trabajo de impresión en el relay.
enum PrintJobStatus { pending, printing, done, failed }

/// Tipos de trabajo de impresión.
class PrintJobType {
  static const String kitchen = 'kitchen';
  static const String bill = 'bill';
  static const String test = 'test';
}

/// Trabajo de impresión encolado en Firestore.
/// Lo crea cualquier dispositivo y lo imprime el primero que lo reclame
/// (transacción pending -> printing) y tenga red hacia la impresora.
class PrintJobEntity {
  final String id;
  final String venueId;
  final String printerId;
  final String printerName;
  final String workspace;
  final String type;
  final String tableNumber;
  final String escPosHex;
  final PrintJobStatus status;
  final String createdBy;
  final String? claimedBy;
  final DateTime createdAt;
  final DateTime? printedAt;
  final String? error;

  const PrintJobEntity({
    required this.id,
    required this.venueId,
    required this.printerId,
    this.printerName = '',
    this.workspace = '',
    required this.type,
    this.tableNumber = '',
    required this.escPosHex,
    this.status = PrintJobStatus.pending,
    this.createdBy = '',
    this.claimedBy,
    required this.createdAt,
    this.printedAt,
    this.error,
  });

  factory PrintJobEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrintJobEntity(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      printerId: data['printerId'] ?? '',
      printerName: data['printerName'] ?? '',
      workspace: data['workspace'] ?? '',
      type: data['type'] ?? PrintJobType.kitchen,
      tableNumber: data['tableNumber'] ?? '',
      escPosHex: data['escPosHex'] ?? '',
      status: PrintJobStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => PrintJobStatus.pending,
      ),
      createdBy: data['createdBy'] ?? '',
      claimedBy: data['claimedBy'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      printedAt: (data['printedAt'] as Timestamp?)?.toDate(),
      error: data['error'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'venueId': venueId,
        'printerId': printerId,
        'printerName': printerName,
        'workspace': workspace,
        'type': type,
        'tableNumber': tableNumber,
        'escPosHex': escPosHex,
        'status': status.name,
        'createdBy': createdBy,
        'claimedBy': claimedBy,
        'createdAt': createdAt,
        'printedAt': printedAt,
        'error': error,
      };
}
