import 'package:flutter_test/flutter_test.dart';
import 'package:lasede_app/data/models/order_dto.dart';
import 'package:lasede_app/services/ticket_splitter.dart';

OrderItemEntity _item(String name, String cat, {String catName = ''}) =>
    OrderItemEntity(
      itemId: name,
      productId: name,
      productName: name,
      quantity: 1,
      unitPrice: 1,
      totalPrice: 1,
      createdAt: DateTime(2026),
      categoryId: cat,
      categoryName: catName,
    );

void main() {
  test('separa comida y bebida por id de categoría', () {
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

  test('separa por nombre cuando el id es autogenerado', () {
    final groups = splitFoodAndDrinks([
      _item('Brascada', 'JpQU0zqY7Uc1cm9ExYWV', catName: 'Bocadillos'),
      _item('Medio Chivito', 'medios-bocadillos',
          catName: 'Medios Bocadillos'),
      _item('Caña', 'qvHtgdFNg55VGw1N51tu', catName: 'Bebidas'),
      _item('Café con leche', 'bd05ui2jV1jSsal8PNXY', catName: 'Cafetería'),
      _item('Olivas', 'JT45Yyt169slbqTZi6QS', catName: 'Varios'),
    ]);
    expect(groups.food.map((e) => e.productName),
        ['Brascada', 'Medio Chivito']);
    expect(groups.drinks.map((e) => e.productName),
        ['Caña', 'Café con leche', 'Olivas']);
  });

  test('sin bebidas deja el tiquet de comida solo', () {
    final groups = splitFoodAndDrinks([_item('Bocata', 'bocadillos')]);
    expect(groups.food.length, 1);
    expect(groups.drinks, isEmpty);
  });
}
