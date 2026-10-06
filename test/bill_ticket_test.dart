import 'package:flutter_test/flutter_test.dart';
import 'package:lasede_app/services/esc_pos_generator.dart';

int physicalLines(List<int> bytes) =>
    String.fromCharCodes(bytes).split('\n').length - 1;

List<int> proforma(int nItems) {
  final items = List.generate(
    nItems,
    (i) => OrderItemData(name: 'Plato $i', quantity: 1, unitPrice: 9.5),
  );
  return EscPosGenerator.generateBillTicket(
    orderId: 'x',
    tableNumber: 'D1',
    items: items,
    subtotal: 9.5 * nItems,
    tax: 0,
    total: 9.5 * nItems,
    createdAt: DateTime(2026, 9, 22, 19, 16, 8),
  );
}

void main() {
  test('proforma compacta: 1 producto sin relleno', () {
    // 5 cabecera + 1 item + sep + total + sep + gracias = 10
    expect(physicalLines(proforma(1)), 10);
  });

  test('proforma compacta: N productos', () {
    // 5 + 30 + 1 + 1 + 1 + 1 = 39
    expect(physicalLines(proforma(30)), 39);
  });

  test('items en triple altura y sin modo invertido', () {
    final bytes = proforma(1);
    // GS ! 0x02 (ancho 1x, alto 3x) presente en items
    var foundTriple = false;
    for (var i = 0; i + 2 < bytes.length; i++) {
      if (bytes[i] == 0x1D && bytes[i + 1] == 0x21 && bytes[i + 2] == 0x02) {
        foundTriple = true;
        break;
      }
    }
    expect(foundTriple, true);
    // ESC { 0 justo tras INIT (1B 40)
    final initIdx = bytes.indexOf(0x1B);
    expect(bytes[initIdx + 1], 0x40);
    expect(bytes.sublist(initIdx + 2, initIdx + 5), [0x1B, 0x7B, 0x00]);
  });

  test('controles bidi invisibles se eliminan (notas no invertidas)', () {
    // U+202E (RLO) colado p. ej. desde un pegado: invertiría el texto impreso
    const rlo = '\u{202E}';
    final items = [
      OrderItemData(
          name: 'Café', quantity: 1, unitPrice: 2, notes: 'sin$rlo hielo')
    ];
    final bytes = EscPosGenerator.generateKitchenTicket(
      orderId: 'x',
      tableNumber: 'D1',
      items: items,
      createdAt: DateTime(2026, 9, 22),
    );
    final text = String.fromCharCodes(bytes);
    expect(text.contains(rlo), false);
    expect(text.contains('sin hielo'), true);
  });

  test('item con extra suma en PVP/IMP y pinta sub-linea', () {
    final items = [
      OrderItemData(name: 'Bocadillo Jamón', quantity: 1, unitPrice: 8.5, modifiers: [
        ModifierData(name: 'Queso', price: 1.5),
      ]),
    ];
    final bytes = EscPosGenerator.generateBillTicket(
      orderId: 'x',
      tableNumber: 'D1',
      items: items,
      subtotal: 8.5,
      tax: 0,
      total: 8.5,
      createdAt: DateTime(2026, 9, 22),
    );
    final text = String.fromCharCodes(bytes);
    expect(text.contains('8,50'), true);
    expect(text.contains('+ Queso'), true);
    expect(text.contains('1,50'), true);
  });

  test('con pago suma una línea y mantiene el pie', () {
    final items = [OrderItemData(name: 'Solo', quantity: 1, unitPrice: 5)];
    final bytes = EscPosGenerator.generateBillTicket(
      orderId: 'x',
      tableNumber: 'D1',
      items: items,
      subtotal: 5,
      tax: 0,
      total: 5,
      paymentMethod: 'Efectivo',
      createdAt: DateTime(2026, 9, 22),
    );
    expect(physicalLines(bytes), 11);
    expect(String.fromCharCodes(bytes).contains('Gracias por su visita'), true);
  });
}
