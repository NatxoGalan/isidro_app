import 'dart:convert';
import '../../data/models/order_dto.dart';

/// Generador de comandos ESC/POS para tickets de cocina/comanda
class EscPosGenerator {
  static const List<int> _init = [0x1B, 0x40]; // ESC @ - Initialize printer
  static const List<int> _cut = [0x1D, 0x56, 0x00]; // GS V 0 - Cut paper
  static const List<int> _feedLines = [0x1B, 0x64, 3]; // ESC d n - Feed n lines
  
  // Text formatting
  static const List<int> _boldOn = [0x1B, 0x45, 1]; // ESC E 1 - Bold on
  static const List<int> _boldOff = [0x1B, 0x45, 0]; // ESC E 0 - Bold off
  static const List<int> _doubleSize = [0x1B, 0x21, 0x30]; // ESC ! 48 - Double height/width
  static const List<int> _normalSize = [0x1B, 0x21, 0x00]; // ESC ! 0 - Normal size
  static const List<int> _centerAlign = [0x1B, 0x61, 1]; // ESC a 1 - Center align
  static const List<int> _leftAlign = [0x1B, 0x61, 0]; // ESC a 0 - Left align
  static const List<int> _underlineOn = [0x1B, 0x2D, 1]; // ESC - 1 - Underline on
  static const List<int> _underlineOff = [0x1B, 0x2D, 0]; // ESC - 0 - Underline off

  /// Genera ticket de cocina para una orden
  static List<int> generateKitchenTicket({
    required String orderId,
    required String tableNumber,
    required List<OrderItemData> items,
    String? notes,
    String? kitchenNotes,
    required DateTime createdAt,
  }) {
    final bytes = <int>[];
    
    // Initialize
    bytes.addAll(_init);
    
    // Header
    bytes.addAll(_centerAlign);
    bytes.addAll(_boldOn);
    bytes.addAll(_doubleSize);
    bytes.addAll(utf8.encode('COCINA\n'));
    bytes.addAll(_normalSize);
    bytes.addAll(_boldOff);
    bytes.addAll(utf8.encode('================\n'));
    
    // Mesa y orden
    bytes.addAll(utf8.encode('Mesa: $tableNumber\n'));
    bytes.addAll(utf8.encode('Orden: ${orderId.substring(0, 8)}\n'));
    bytes.addAll(utf8.encode('Fecha: ${_formatDateTime(createdAt)}\n'));
    bytes.addAll(utf8.encode('================\n'));
    
    // Items
    bytes.addAll(_leftAlign);
    for (final item in items) {
      // Nombre y cantidad
      bytes.addAll(_boldOn);
      bytes.addAll(utf8.encode('${item.quantity}x ${item.name}\n'));
      bytes.addAll(_boldOff);
      
      // Modificadores
      if (item.modifiers.isNotEmpty) {
        for (final mod in item.modifiers) {
          bytes.addAll(utf8.encode('  + ${mod.name}\n'));
        }
      }
      
      // Notas del item
      if (item.notes.isNotEmpty) {
        bytes.addAll(_underlineOn);
        bytes.addAll(utf8.encode('  Nota: ${item.notes}\n'));
        bytes.addAll(_underlineOff);
      }
      
      // Takeaway
      if (item.isTakeaway) {
        bytes.addAll(utf8.encode('  *** PARA LLEVAR ***\n'));
      }
      
      bytes.addAll(utf8.encode('\n'));
    }
    
    // Notas de cocina
    if (kitchenNotes != null && kitchenNotes.isNotEmpty) {
      bytes.addAll(utf8.encode('================\n'));
      bytes.addAll(_underlineOn);
      bytes.addAll(_boldOn);
      bytes.addAll(utf8.encode('NOTAS COCINA:\n'));
      bytes.addAll(_boldOff);
      bytes.addAll(utf8.encode(kitchenNotes));
      bytes.addAll(_underlineOff);
      bytes.addAll(utf8.encode('\n'));
    }
    
    // Notas generales
    if (notes != null && notes.isNotEmpty) {
      bytes.addAll(utf8.encode('================\n'));
      bytes.addAll(utf8.encode('NOTAS: $notes\n'));
    }
    
    // Footer
    bytes.addAll(utf8.encode('================\n'));
    bytes.addAll(_centerAlign);
    bytes.addAll(utf8.encode('--- FIN COMANDA ---\n'));
    
    // Cut and feed
    bytes.addAll(_feedLines);
    bytes.addAll(_cut);
    
    return bytes;
  }

  /// Genera ticket de comanda (para camarero)
  static List<int> generateComandaTicket({
    required String orderId,
    required String tableNumber,
    required List<OrderItemData> items,
    String? notes,
    required DateTime createdAt,
  }) {
    final bytes = <int>[];
    
    bytes.addAll(_init);
    
    // Header
    bytes.addAll(_centerAlign);
    bytes.addAll(_boldOn);
    bytes.addAll(_doubleSize);
    bytes.addAll(utf8.encode('COMANDA\n'));
    bytes.addAll(_normalSize);
    bytes.addAll(_boldOff);
    bytes.addAll(utf8.encode('================\n'));
    
    bytes.addAll(_leftAlign);
    bytes.addAll(utf8.encode('Mesa: $tableNumber\n'));
    bytes.addAll(utf8.encode('Orden: ${orderId.substring(0, 8)}\n'));
    bytes.addAll(utf8.encode('Fecha: ${_formatDateTime(createdAt)}\n'));
    bytes.addAll(utf8.encode('================\n'));
    
    for (final item in items) {
      bytes.addAll(utf8.encode('${item.quantity}x ${item.name}\n'));
      if (item.modifiers.isNotEmpty) {
        for (final mod in item.modifiers) {
          bytes.addAll(utf8.encode('  + ${mod.name}\n'));
        }
      }
      if (item.notes.isNotEmpty) {
        bytes.addAll(utf8.encode('  Nota: ${item.notes}\n'));
      }
      if (item.isTakeaway) {
        bytes.addAll(utf8.encode('  *** PARA LLEVAR ***\n'));
      }
      bytes.addAll(utf8.encode('\n'));
    }
    
    if (notes != null && notes.isNotEmpty) {
      bytes.addAll(utf8.encode('================\n'));
      bytes.addAll(utf8.encode('Notas: $notes\n'));
    }
    
    bytes.addAll(utf8.encode('================\n'));
    bytes.addAll(_centerAlign);
    bytes.addAll(utf8.encode('--- FIN COMANDA ---\n'));
    
    bytes.addAll(_feedLines);
    bytes.addAll(_cut);
    
    return bytes;
  }

  /// Genera ticket de cuenta/cobro
  static List<int> generateBillTicket({
    required String orderId,
    required String tableNumber,
    required List<OrderItemData> items,
    required double subtotal,
    required double tax,
    required double total,
    String? paymentMethod,
    required DateTime createdAt,
  }) {
    final bytes = <int>[];
    
    bytes.addAll(_init);
    
    // Header
    bytes.addAll(_centerAlign);
    bytes.addAll(_boldOn);
    bytes.addAll(_doubleSize);
    bytes.addAll(utf8.encode('CUENTA\n'));
    bytes.addAll(_normalSize);
    bytes.addAll(_boldOff);
    bytes.addAll(utf8.encode('================\n'));
    
    bytes.addAll(_leftAlign);
    bytes.addAll(utf8.encode('Mesa: $tableNumber\n'));
    bytes.addAll(utf8.encode('Orden: ${orderId.substring(0, 8)}\n'));
    bytes.addAll(utf8.encode('Fecha: ${_formatDateTime(createdAt)}\n'));
    bytes.addAll(utf8.encode('================\n'));
    
    for (final item in items) {
      final itemTotal = item.unitPrice * item.quantity;
      bytes.addAll(utf8.encode('${item.quantity}x ${item.name}  ${itemTotal.toStringAsFixed(2)}€\n'));
    }
    
    bytes.addAll(utf8.encode('================\n'));
    bytes.addAll(utf8.encode('Subtotal: ${subtotal.toStringAsFixed(2)}€\n'));
    bytes.addAll(utf8.encode('IVA: ${tax.toStringAsFixed(2)}€\n'));
    bytes.addAll(_boldOn);
    bytes.addAll(utf8.encode('TOTAL: ${total.toStringAsFixed(2)}€\n'));
    bytes.addAll(_boldOff);
    
    if (paymentMethod != null) {
      bytes.addAll(utf8.encode('Método: $paymentMethod\n'));
    }
    
    bytes.addAll(utf8.encode('================\n'));
    bytes.addAll(_centerAlign);
    bytes.addAll(utf8.encode('¡GRACIAS POR SU VISITA!\n'));
    
    bytes.addAll(_feedLines);
    bytes.addAll(_cut);
    
    return bytes;
  }

  /// Convierte bytes a hex string para envío a Sunmi
  static String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Modelo simplificado para items de orden en tickets
class OrderItemData {
  final String name;
  final int quantity;
  final double unitPrice;
  final List<ModifierData> modifiers;
  final String notes;
  final bool isTakeaway;

  const OrderItemData({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.modifiers = const [],
    this.notes = '',
    this.isTakeaway = false,
  });
}

class ModifierData {
  final String name;
  final double price;

  const ModifierData({required this.name, this.price = 0.0});
}

/// Extension para convertir OrderItemEntity a OrderItemData
extension OrderItemEntityExtension on OrderItemEntity {
  OrderItemData toOrderItemData() {
    return OrderItemData(
      name: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      modifiers: modifiers.map((m) => ModifierData(
        name: m.optionName ?? m.modifierName,
        price: m.additionalPrice,
      )).toList(),
      notes: notes,
      isTakeaway: isTakeaway,
    );
  }
}