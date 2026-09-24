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
