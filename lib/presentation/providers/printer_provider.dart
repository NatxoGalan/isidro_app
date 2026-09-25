import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/constants.dart';
import '../../data/models/print_dto.dart';
import '../../data/models/order_dto.dart';
import '../../data/models/printer_dto.dart';
import '../../data/models/print_job_dto.dart';
import '../../services/esc_pos_generator.dart';
import '../../services/printer_service.dart';
import '../../services/print_station.dart';
import '../../data/repositories/printer_repository.dart';
import 'auth_provider.dart';

/// Provider para la cola de impresión
final printQueueProvider = StateNotifierProvider<PrintQueueNotifier, List<PrintQueueTicket>>((ref) {
  return PrintQueueNotifier();
});

class PrintQueueNotifier extends StateNotifier<List<PrintQueueTicket>> {
  PrintQueueNotifier() : super([]);

  /// Añade ticket a la cola de impresión
  void addTicket({
    required String orderId,
    required String tableNumber,
    required PrintType type,
    required List<PrintItemData> items,
    String? notes,
    required String escPosHex,
  }) {
    final ticket = PrintQueueTicket(
      id: const Uuid().v4(),
      orderId: orderId,
      tableNumber: tableNumber,
      type: type,
      items: items,
      notes: notes,
      createdAt: DateTime.now(),
      escPosHex: escPosHex,
      itemsCount: items.length,
    );
    state = [...state, ticket];
  }

  /// Marca ticket como impreso
  void markPrinted(String ticketId) {
    state = state.map((ticket) {
      if (ticket.id == ticketId) {
        return ticket.copyWith(
          status: PrintStatus.printed,
          printedAt: DateTime.now(),
        );
      }
      return ticket;
    }).toList();
  }

  /// Marca ticket para reimpresión
  void reprint(String ticketId) {
    state = state.map((ticket) {
      if (ticket.id == ticketId) {
        return ticket.copyWith(
          status: PrintStatus.pending,
          printedAt: null,
        );
      }
      return ticket;
    }).toList();
  }

  /// Imprime todos los pendientes
  void printAllPending() {
    state = state.map((ticket) {
      if (ticket.status == PrintStatus.pending) {
        return ticket.copyWith(
          status: PrintStatus.printed,
          printedAt: DateTime.now(),
        );
      }
      return ticket;
    }).toList();
  }

  /// Limpia historial de impresos (mantiene pendientes)
  void clearHistory() {
    state = state.where((t) => t.status == PrintStatus.pending).toList();
  }

  /// Limpia toda la cola
  void clearAll() {
    state = [];
  }

  /// Elimina ticket específico
  void removeTicket(String ticketId) {
    state = state.where((t) => t.id != ticketId).toList();
  }
}

/// Provider para generar tickets ESC/POS
final escPosGeneratorProvider = Provider<EscPosGenerator>((ref) => EscPosGenerator());

/// Provider para generar ticket de cocina desde orden
final kitchenTicketGeneratorProvider = Provider<Function({
  required String orderId,
  required String tableNumber,
  required List<OrderItemEntity> items,
  String? notes,
  String? kitchenNotes,
  String? waiterName,
  String? stationLabel,
  required DateTime createdAt,
})>((ref) {
  return ({
    required String orderId,
    required String tableNumber,
    required List<OrderItemEntity> items,
    String? notes,
    String? kitchenNotes,
    String? waiterName,
    String? stationLabel,
    required DateTime createdAt,
  }) {
    final itemsData = items.map((item) => OrderItemData(
      name: item.productName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      modifiers: item.modifiers.map((m) => ModifierData(
        name: m.optionName ?? m.modifierName,
        price: m.additionalPrice,
      )).toList(),
      notes: item.notes,
      isTakeaway: item.isTakeaway,
    )).toList();

    final bytes = EscPosGenerator.generateKitchenTicket(
      orderId: orderId,
      tableNumber: tableNumber,
      items: itemsData,
      notes: notes,
      kitchenNotes: kitchenNotes,
      waiterName: waiterName,
      stationLabel: stationLabel,
      createdAt: createdAt,
    );

    return EscPosGenerator.bytesToHex(bytes);
  };
});

/// Provider para generar ticket de comanda
final comandaTicketGeneratorProvider = Provider<Function({
  required String orderId,
  required String tableNumber,
  required List<OrderItemEntity> items,
  String? notes,
  required DateTime createdAt,
})>((ref) {
  return ({
    required String orderId,
    required String tableNumber,
    required List<OrderItemEntity> items,
    String? notes,
    required DateTime createdAt,
  }) {
    final itemsData = items.map((item) => OrderItemData(
      name: item.productName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      modifiers: item.modifiers.map((m) => ModifierData(
        name: m.optionName ?? m.modifierName,
        price: m.additionalPrice,
      )).toList(),
      notes: item.notes,
      isTakeaway: item.isTakeaway,
    )).toList();

    final bytes = EscPosGenerator.generateComandaTicket(
      orderId: orderId,
      tableNumber: tableNumber,
      items: itemsData,
      notes: notes,
      createdAt: createdAt,
    );

    return EscPosGenerator.bytesToHex(bytes);
  };
});

/// Provider para generar ticket de cuenta
final billTicketGeneratorProvider = Provider<Function({
  required String orderId,
  required String tableNumber,
  required List<OrderItemEntity> items,
  String? notes,
  required double subtotal,
  required double tax,
  required double total,
  String? paymentMethod,
  String? waiterName,
  required DateTime createdAt,
})>((ref) {
  return ({
    required String orderId,
    required String tableNumber,
    required List<OrderItemEntity> items,
    String? notes,
    required double subtotal,
    required double tax,
    required double total,
    String? paymentMethod,
    String? waiterName,
    required DateTime createdAt,
  }) {
    final itemsData = items.map((item) => OrderItemData(
      name: item.productName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      modifiers: item.modifiers.map((m) => ModifierData(
        name: m.optionName ?? m.modifierName,
        price: m.additionalPrice,
      )).toList(),
      notes: item.notes,
      isTakeaway: item.isTakeaway,
    )).toList();

    final bytes = EscPosGenerator.generateBillTicket(
      orderId: orderId,
      tableNumber: tableNumber,
      items: itemsData,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: notes,
      waiterName: waiterName,
      createdAt: createdAt,
    );

    return EscPosGenerator.bytesToHex(bytes);
  };
});

/// true cuando la cuenta logueada es de pruebas: los flujos funcionan
/// igual pero la impresión se simula (ni red directa ni relay).
final isTestModeProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).value?.isTest ?? false;
});

/// Stream de impresoras configuradas (Firestore, compartido entre dispositivos)
final printersProvider = StreamProvider<List<PrinterEntity>>((ref) {
  return ref
      .read(printerRepositoryProvider)
      .watchPrinters(Constants.defaultVenueId);
});

/// Acciones sobre impresoras: alta, edición, borrado, principal y test.
class PrinterActionsNotifier extends StateNotifier<AsyncValue<void>> {
  PrinterActionsNotifier(this._repo) : super(const AsyncValue.data(null));

  final PrinterRepository _repo;

  Future<void> _run(Future<void> Function() fn) async {
    state = const AsyncValue.loading();
    try {
      await fn();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> addPrinter({
    required String name,
    required String ip,
    int port = 9100,
    bool isPrincipal = false,
    List<String> workspaces = const [],
  }) {
    return _run(() => _repo.addPrinter(
          venueId: Constants.defaultVenueId,
          name: name,
          ip: ip,
          port: port,
          isPrincipal: isPrincipal,
          workspaces: workspaces,
        ));
  }

  Future<void> updatePrinter(String printerId, Map<String, dynamic> data) {
    return _run(() => _repo.updatePrinter(
          venueId: Constants.defaultVenueId,
          printerId: printerId,
          data: data,
        ));
  }

  Future<void> deletePrinter(String printerId) {
    return _run(() => _repo.deletePrinter(
          venueId: Constants.defaultVenueId,
          printerId: printerId,
        ));
  }

  Future<void> setPrincipal(List<PrinterEntity> printers, String printerId) {
    return _run(() => _repo.setPrincipal(
          venueId: Constants.defaultVenueId,
          printers: printers,
          printerId: printerId,
        ));
  }

  /// Comprueba conexión TCP con la impresora.
  Future<PrinterConnectionStatus> testConnection(PrinterEntity printer) {
    return PrinterService.checkConnection(printer);
  }

  /// Imprime ticket de prueba en la impresora.
  Future<bool> printTest(PrinterEntity printer) {
    final bytes = EscPosGenerator.generateTestTicket(
      printerName: printer.name,
      ip: printer.ip,
    );
    return PrinterService.printBytes(printer, bytes);
  }
}

final printerActionsProvider =
    StateNotifierProvider<PrinterActionsNotifier, AsyncValue<void>>((ref) {
  return PrinterActionsNotifier(ref.read(printerRepositoryProvider));
});

/// Impresoras de un espacio de trabajo (p. ej. Cocina). Si no hay
/// ninguna configurada para ese espacio, devuelve la principal.
List<PrinterEntity> printersForWorkspace(
  List<PrinterEntity> all,
  String workspace,
) {
  final match = all
      .where((p) => p.isConfigured && p.workspaces.contains(workspace))
      .toList();
  if (match.isNotEmpty) return match;
  final principal = all.where((p) => p.isConfigured && p.isPrincipal).toList();
  if (principal.isNotEmpty) return principal;
  return all.where((p) => p.isConfigured).toList();
}

/// Cola reciente de trabajos de impresión (relay).
final printJobsProvider = StreamProvider<List<PrintJobEntity>>((ref) {
  return ref
      .read(printerRepositoryProvider)
      .watchRecentJobs(Constants.defaultVenueId);
});

/// Estación de impresión: procesa trabajos pendientes en este dispositivo.
final printStationProvider = Provider<PrintStationService>((ref) {
  final service =
      PrintStationService(ref.read(printerRepositoryProvider));
  ref.onDispose(() => service.stop());
  return service;
});

/// Impresora principal (para proforma/cuenta). Null si no hay configurada.
PrinterEntity? principalPrinter(List<PrinterEntity> all) {
  final configured = all.where((p) => p.isConfigured).toList();
  if (configured.isEmpty) return null;
  return configured.firstWhere(
    (p) => p.isPrincipal,
    orElse: () => configured.first,
  );
}