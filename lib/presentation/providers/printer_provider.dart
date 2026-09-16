import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/print_dto.dart';
import '../../data/models/order_dto.dart';
import '../../services/esc_pos_generator.dart';

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
  required DateTime createdAt,
})>((ref) {
  return ({
    required String orderId,
    required String tableNumber,
    required List<OrderItemEntity> items,
    String? notes,
    String? kitchenNotes,
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
      createdAt: createdAt,
    );

    return EscPosGenerator.bytesToHex(bytes);
  };
});