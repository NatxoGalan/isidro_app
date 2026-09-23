import 'package:flutter_test/flutter_test.dart';
import 'package:lasede_app/services/esc_pos_generator.dart';

int physicalLines(List<int> bytes) =>
    String.fromCharCodes(bytes).split('\n').length - 1;

List<int> proforma(int nItems, {int minLines = 32}) {
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
    minLines: minLines,
    createdAt: DateTime(2026, 9, 22, 19, 16, 8),
  );
}

void main() {
  test('proforma corta se rellena hasta minLines', () {
    // 5 cabecera + 1 item + sep + total + 20 relleno + sep + gracias = 30 físicas
    // (32 equivalentes contando doble altura x2)
    expect(physicalLines(proforma(1)), 30);
  });

  test('proforma larga no se rellena', () {
    // 5 + 30 + 1 + 1 + 0 + 1 + 1 = 39
    expect(physicalLines(proforma(30)), 39);
  });

  test('con pago suma una línea', () {
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
    // used = 6+1+1+2+1 = 11 → pad = 32-11-2 = 19 → físicas = 5+1+1+1+1+19+2 = 30
    expect(physicalLines(bytes), 30);
    expect(String.fromCharCodes(bytes).contains('Gracias por su visita'), true);
  });
}
