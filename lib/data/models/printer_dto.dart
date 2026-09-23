import 'package:cloud_firestore/cloud_firestore.dart';

/// Espacios de trabajo que atiende una impresora (destinos de impresión).
/// Se reutilizan los valores de PrinterTarget de las órdenes.
class PrinterWorkspace {
  static const String bar = 'bar';
  static const String kitchen = 'kitchen';
}

/// Impresora de red (WiFi) configurada en el local.
class PrinterEntity {
  final String id;
  final String venueId;
  final String name;
  final String ip;
  final int port;
  final bool isPrincipal;
  final List<String> workspaces;

  const PrinterEntity({
    required this.id,
    required this.venueId,
    required this.name,
    this.ip = '',
    this.port = 9100,
    this.isPrincipal = false,
    this.workspaces = const [],
  });

  bool get isConfigured => ip.trim().isNotEmpty;

  String get connectionLabel => isConfigured ? ip : 'Sin configurar';

  factory PrinterEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrinterEntity(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      name: data['name'] ?? '',
      ip: data['ip'] ?? '',
      port: (data['port'] as num?)?.toInt() ?? 9100,
      isPrincipal: data['isPrincipal'] ?? false,
      workspaces: List<String>.from(data['workspaces'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'venueId': venueId,
        'name': name,
        'ip': ip,
        'port': port,
        'isPrincipal': isPrincipal,
        'workspaces': workspaces,
      };

  PrinterEntity copyWith({
    String? id,
    String? venueId,
    String? name,
    String? ip,
    int? port,
    bool? isPrincipal,
    List<String>? workspaces,
  }) {
    return PrinterEntity(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      isPrincipal: isPrincipal ?? this.isPrincipal,
      workspaces: workspaces ?? this.workspaces,
    );
  }
}
