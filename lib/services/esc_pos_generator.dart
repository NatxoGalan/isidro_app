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
  static const List<int> _doubleHeight = [0x1B, 0x21, 0x10]; // ESC ! 16 - Double height
  static const List<int> _normalSize = [0x1B, 0x21, 0x00]; // ESC ! 0 - Normal size
  static const List<int> _centerAlign = [0x1B, 0x61, 1]; // ESC a 1 - Center align
  static const List<int> _leftAlign = [0x1B, 0x61, 0]; // ESC a 0 - Left align

  /// Ancho de papel 80mm en caracteres (modo normal)
  static const int _cols = 42;
  static String get _sep => ''.padRight(_cols, '-');

  /// Codifica texto en latin1 (tildes/ñ de la codepage típica ESC/POS).
  /// Los caracteres fuera de latin1 se sustituyen por '?'.
  static List<int> _enc(String s) {
    final out = <int>[];
    for (final r in s.runes) {
      out.add(r < 256 ? r : 0x3F);
    }
    return out;
  }

  /// Precio en formato español: 9,50
  static String _price(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  /// 22/09 19:15
  static String _fmtShort(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  /// 22/9/2026 - 19:16:08
  static String _fmtLong(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} - $h:$min:$s';
  }

  static String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return s.substring(0, max);
  }

  /// Genera ticket de cocina "Nuevo pedido" para una orden
  static List<int> generateKitchenTicket({
    required String orderId,
    required String tableNumber,
    required List<OrderItemData> items,
    String? notes,
    String? kitchenNotes,
    String? waiterName,
    required DateTime createdAt,
  }) {
    final bytes = <int>[];

    bytes.addAll(_init);

    // Título
    bytes.addAll(_centerAlign);
    bytes.addAll(_enc('Nuevo pedido\n'));
    bytes.addAll(_enc('$_sep\n'));

    // Mesa en grande
    bytes.addAll(_leftAlign);
    bytes.addAll(_boldOn);
    bytes.addAll(_doubleSize);
    bytes.addAll(_enc('Mesa: $tableNumber\n'));
    bytes.addAll(_normalSize);
    bytes.addAll(_boldOff);

    // Camarero y fecha
    if (waiterName != null && waiterName.isNotEmpty) {
      bytes.addAll(_enc('Por: $waiterName\n'));
    }
    bytes.addAll(_enc('${_fmtShort(createdAt)}\n'));
    bytes.addAll(_enc('$_sep\n'));

    // Items en grande con sus notas
    var totalPlatos = 0;
    for (final item in items) {
      totalPlatos += item.quantity;
      bytes.addAll(_boldOn);
      bytes.addAll(_doubleHeight);
      bytes.addAll(_enc('${item.quantity}x ${item.name}\n'));
      bytes.addAll(_normalSize);
      bytes.addAll(_boldOff);

      for (final mod in item.modifiers) {
        bytes.addAll(_enc('  + ${mod.name}\n'));
      }

      // Nota del producto (si tiene)
      if (item.notes.isNotEmpty) {
        bytes.addAll(_boldOn);
        bytes.addAll(_enc('  >> ${item.notes}\n'));
        bytes.addAll(_boldOff);
      }

      if (item.isTakeaway) {
        bytes.addAll(_enc('  *** PARA LLEVAR ***\n'));
      }

      bytes.addAll(_enc('\n'));
    }

    // Notas de cocina
    final extraNotes = [
      if (kitchenNotes != null && kitchenNotes.isNotEmpty) kitchenNotes,
      if (notes != null && notes.isNotEmpty) notes,
    ].join('\n');
    if (extraNotes.isNotEmpty) {
      bytes.addAll(_enc('$_sep\n'));
      bytes.addAll(_boldOn);
      bytes.addAll(_enc('NOTAS:\n'));
      bytes.addAll(_boldOff);
      bytes.addAll(_enc('$extraNotes\n'));
    }

    bytes.addAll(_enc('$_sep\n'));
    bytes.addAll(_enc('Total platos: $totalPlatos\n'));

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

  /// Genera factura proforma (ticket de cuenta antes de cerrar la mesa)
  static List<int> generateBillTicket({
    required String orderId,
    required String tableNumber,
    required List<OrderItemData> items,
    required double subtotal,
    required double tax,
    required double total,
    String? paymentMethod,
    String? waiterName,
    String venueName = 'La Sede',
    required DateTime createdAt,
  }) {
    final bytes = <int>[];

    bytes.addAll(_init);

    // Cabecera
    bytes.addAll(_centerAlign);
    bytes.addAll(_boldOn);
    bytes.addAll(_doubleHeight);
    bytes.addAll(_enc('$venueName\n'));
    bytes.addAll(_normalSize);
    bytes.addAll(_enc('Factura proforma\n'));
    bytes.addAll(_boldOff);
    bytes.addAll(_enc('${_fmtLong(createdAt)}\n'));

    // Atendido por + Mesa en la misma línea
    bytes.addAll(_leftAlign);
    final mesa = 'Mesa: $tableNumber';
    var left = 'Atendido por: ${(waiterName ?? '').trim()}';
    final gap = _cols - left.length - mesa.length;
    if (gap >= 1) {
      left = '$left${''.padRight(gap)}$mesa';
    } else {
      left = '${_truncate(left, _cols - mesa.length - 1)} $mesa';
    }
    bytes.addAll(_enc('$left\n'));

    // Cabecera de columnas: UND NOMBRE | PVP | IMP
    const qtyW = 4; // "1 x "
    const pvpW = 7;
    const impW = 7;
    final nameW = _cols - qtyW - pvpW - impW;
    final header = '${'UND'.padRight(qtyW)}${'NOMBRE'.padRight(nameW)}${'PVP'.padLeft(pvpW)}${'IMP'.padLeft(impW)}';
    bytes.addAll(_boldOn);
    bytes.addAll(_enc('$header\n'));
    bytes.addAll(_boldOff);

    // Items
    for (final item in items) {
      final itemTotal = item.unitPrice * item.quantity;
      final qty = '${item.quantity} x ';
      final name = _truncate(item.name, nameW);
      final line = '${qty.padRight(qtyW)}${name.padRight(nameW)}'
          '${_price(item.unitPrice).padLeft(pvpW)}${_price(itemTotal).padLeft(impW)}';
      bytes.addAll(_enc('$line\n'));
    }

    bytes.addAll(_enc('$_sep\n'));

    // Total en grande
    final totalStr = _price(total);
    bytes.addAll(_boldOn);
    bytes.addAll(_doubleHeight);
    bytes.addAll(_enc('${'Total'.padRight(_cols - totalStr.length)}$totalStr\n'));
    bytes.addAll(_normalSize);
    bytes.addAll(_boldOff);

    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      bytes.addAll(_enc('Pagado: $paymentMethod\n'));
    }

    bytes.addAll(_enc('$_sep\n'));
    bytes.addAll(_centerAlign);
    bytes.addAll(_boldOn);
    bytes.addAll(_enc('Gracias por su visita\n'));
    bytes.addAll(_boldOff);

    bytes.addAll(_feedLines);
    bytes.addAll(_cut);

    return bytes;
  }

  /// Genera ticket de prueba de impresora
  static List<int> generateTestTicket({
    required String printerName,
    required String ip,
  }) {
    final bytes = <int>[];

    bytes.addAll(_init);
    bytes.addAll(_centerAlign);
    bytes.addAll(_boldOn);
    bytes.addAll(_doubleHeight);
    bytes.addAll(_enc('PRUEBA\n'));
    bytes.addAll(_normalSize);
    bytes.addAll(_boldOff);
    bytes.addAll(_enc('$printerName\n'));
    bytes.addAll(_enc('$ip\n'));
    bytes.addAll(_enc('${_fmtLong(DateTime.now())}\n'));
    bytes.addAll(_enc('$_sep\n'));
    bytes.addAll(_enc('Impresora OK\n'));

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