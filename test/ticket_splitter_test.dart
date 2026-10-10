import 'package:flutter_test/flutter_test.dart';
import 'package:lasede_app/data/models/order_dto.dart';
import 'package:lasede_app/services/ticket_splitter.dart';

OrderItemEntity _item(String name, String cat) => OrderItemEntity(
      itemId: name,
      productId: name,
      productName: name,
      quantity: 1,
      unitPrice: 1,
      totalPrice: 1,
      createdAt: DateTime(2026),
      categoryId: cat,
    );

void main() {
  test('separa comida y bebida por categoría', () {
    final groups = splitFoodAndDrinks([
      _item('Bocata', 'bocadillos'),
      _item('Cerveza', 'bebidas'),
      _item('Café', 'cafeteria'),
      _item('Tapa', 'tapas'),
      _item('Refresco', 'varios'),
    ]);
    expect(groups.food.map((e) => e.productName), ['Bocata', 'Tapa']);
    expect(groups.drinks.map((e) => e.productName),
        ['Cerveza', 'Café', 'Refresco']);
  });

  test('sin bebidas deja el tiquet de comida solo', () {
    final groups = splitFoodAndDrinks([_item('Bocata', 'bocadillos')]);
    expect(groups.food.length, 1);
    expect(groups.drinks, isEmpty);
  });
}
